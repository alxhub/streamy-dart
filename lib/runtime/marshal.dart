part of streamy.runtime;

void marshalToString(List<String> fields, Map data) {
  fields
    .where(data.containsKey)
    .forEach((key) {
    var value = data[key];
    if (value != null) {
      data[key] = value.toString();
    }
  });
}

void unmarshalInt64s(List<String> fields, Map data) {
  fields
    .where(data.containsKey)
    .forEach((key) {
      data[key] = unmarshalInt64Data(data[key]);
    });
}

unmarshalInt64Data(data) {
  if (data == null) {
    return null;
  } else if (data is List) {
    return data.map(unmarshalInt64Data).toList();
  } else if (data is String) {
    return Int64.parseInt(data);
  } else {
    return new Int64(data);
  }
}

void unmarshalDoubles(List<String> fields, Map data) {
  fields
    .where(data.containsKey)
    .forEach((key) {
      var value = data[key];
      if (value != null) {
        if (value is List) {
        } else if (value is String) {
          data[key] = double.parse(value);
        }
      }
    });
}

unmarshalDoubleData(data) {
  if (data == null) {
    return null;
  } else if (data is List) {
    return data.map(unmarshalDoubleData).toList();
  } else if (data is String) {
    return double.parse(data);
  } else {
    return data;
  }
}

void handleEntities(marshaller, Map handlers, Map data, bool marshal) {
  handlers
    .keys
    .where(data.containsKey)
    .forEach((key) {
      data[key] = handleEntityData(data[key], marshaller, handlers[key], marshal);
    });
}

handleEntityData(data, marshaller, handler, bool marshal) {
  if (data == null) {
    return null;
  } else if (data is List) {
    return data.map((v) => handleEntityData(v, marshaller, handler, marshal)).toList();
  } else {
    return handler(marshaller, data, marshal);
  }
}