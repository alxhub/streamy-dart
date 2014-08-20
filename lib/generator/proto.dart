part of streamy.generator;

class ProtoRef {
  final List<String> package;
  final String messageType;

  ProtoRef(this.package, this.messageType);
  
  String get packageString => package.join('.');

  factory ProtoRef.fromString(String type) {
    var pieces = type.split('.').toList();
    if (pieces[0].isEmpty) {
      pieces.removeAt(0);
    }
    return new ProtoRef(pieces, pieces.removeLast());
  }
}

/// Generate a Streamy [Api] from a [ProtoConfig].
Future<Api> fromProto(ProtoConfig config) {
  // Read the proto file.
  var root = config.root;
  
  // Determine commandline to protoc to get the descriptor.
  // TODO(Alex): Since protoc reads the proto file directly, barback doesn't
  // count it as a dependency (or any of its dependencies). Thus, the
  // edit-save-refresh cycle fails when editing .proto files currently.
  var protoPath = config.root.replaceAll(r'$CWD', io.Directory.current.path);
  if (!protoPath.endsWith('/')) {
    protoPath = '$protoPath/';
  }
  
  var importMap = {};
  config.dependencies.forEach((package, dep) =>
      importMap[package] = dep.prefix);
  var protocArgs = ['-o/dev/stdout', '--proto_path=$protoPath',
      '$protoPath${config.sourceFile}'];
  return io.Process
    .start('protoc', protocArgs)
    .then((protoc) {
      io.stderr.addStream(protoc.stderr);
      return protoc;
    })
    .then((protoc) => protoc.stdout.toList())
    .then((data) => data.expand((v) => v).toList())
    .then((data) => new protoSchema.FileDescriptorSet.fromBuffer(data))
    .then((proto) => proto.file.single)
    .then((proto) {
      importMap[proto.package] = '';
      var deps = config.dependencies.values.toList();
      var api = new Api(config.name, dependencies: deps);
      proto.messageType.forEach((message) {
        var schema = new Schema(message.name);
        message.enumType.forEach((enumType) {
          var enum = new Enum('${message.name}_${enumType.name}');
          enum.values.addAll(enumType.value.map((value) =>
            new EnumValue(value.name, value.number)
          ));
          api.enums.add(enum);
        });
        message.field.forEach((field) {
          var type = const TypeRef.any();
          switch (field.type) {
            case protoSchema.FieldDescriptorProto_Type.TYPE_INT32:
              type = const TypeRef.integer();
              break;
            case protoSchema.FieldDescriptorProto_Type.TYPE_INT64:
              type = const TypeRef.int64();
              break;
            case protoSchema.FieldDescriptorProto_Type.TYPE_STRING:
              type = const TypeRef.string();
              break;
            case protoSchema.FieldDescriptorProto_Type.TYPE_MESSAGE:
              type = _toProtoSchemaRef(importMap,
                  new ProtoRef.fromString(field.typeName));
              break;
            default:
              throw new Exception("Unknown: ${field.name} / ${field.type}");
          }
          if (field.label ==
              protoSchema.FieldDescriptorProto_Label.LABEL_REPEATED) {
            type = new TypeRef.list(type);
          }
          schema.properties[field.name] =
              new Field(field.name, 'Desc', type, "${field.number}",
                  key: "${field.number}");
        });
        api.types[schema.name] = schema;
      });
      proto.service.forEach((svc) {
        var resource = new Resource(svc.name);
        svc.method.forEach((meth) {
          var payloadType = new SchemaTypeRef(meth.inputType.split('.')[2]);
          var responseType = new SchemaTypeRef(meth.outputType.split('.')[2]);
          var method = new Method(meth.name, new Path('/${svc.name}.${meth.name}'), 'POST', payloadType, responseType);
          resource.methods[method.name] = method;
        });
        api.resources[resource.name] = resource;
      });
      return api;
    });
}

SchemaTypeRef _toProtoSchemaRef(Map imports, ProtoRef ref) {
  if (ref.package.isEmpty) {
    // Local import case.
    return new TypeRef.schema(ref.messageType);
  }
  var package = ref.packageString;
  if (!imports.containsKey(package)) {
    throw new Exception('Unknown imported package: $package');
  }
  if (imports[package] == '') {
    // Also a local case.
    return new TypeRef.schema(ref.messageType);
  }
  return new TypeRef.dependency(ref.messageType, imports[package]);
}