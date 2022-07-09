import axios, { type AxiosResponse } from 'axios'
import { deepCamelizeKeys } from '~/helpers/object'

// Configure axios to camelize response data from Rails.
axios.interceptors.response.use(camelizeResponse, (error) => {
  if (error.response) camelizeResponse(error.response)
  throw error
})

// Converts the snake_case from Ruby to camelCase in JS.
function camelizeResponse (response: AxiosResponse) {
  if (response.data) response.data = deepCamelizeKeys(response.data)
  return response
}

export default axios
