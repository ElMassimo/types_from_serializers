import { camelCase, snakeCase, isPlainObject, mapKeys, mapValues } from 'lodash-es'

function convertKeys (object: any, keyConverter = camelCase) {
  if (isPlainObject(object))
    return mapKeys(object, (value, key) => keyConverter(key))
  else
    return object
}

function deepConvertKeys (object: any, keyConverter = decamelizeKeys, decamelizer = snakeCase): any {
  if (isPlainObject(object)) {
    return mapValues(
      keyConverter(object, decamelizer),
      (value: any) => deepConvertKeys(value, keyConverter, decamelizer),
    )
  }

  if (Array.isArray(object))
    return object.map((item: any) => deepConvertKeys(item, keyConverter, decamelizer))

  return object
}

// Public: Converts all object keys to camelCase, preserving the values.
export function camelizeKeys (object: any) {
  return convertKeys(object, camelCase)
}

// Public: Converts all object keys to snake_case, preserving the values.
export function decamelizeKeys (object: any, decamelizer = snakeCase) {
  return convertKeys(object, decamelizer)
}

// Public: Converts all object keys to camelCase, as well as nested objects, or
// objects in nested arrays.
export function deepCamelizeKeys (object: any) {
  return deepConvertKeys(object, camelizeKeys)
}

// Public: Converts all object keys to snake_case, as well as nested objects, or
// objects in nested arrays.
export function deepDecamelizeKeys (object: any, decamelizer = snakeCase) {
  return deepConvertKeys(object, decamelizeKeys, decamelizer)
}
