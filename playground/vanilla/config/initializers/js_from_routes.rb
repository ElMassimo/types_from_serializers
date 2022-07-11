if Rails.env.development?
  JsFromRoutes.config do |config|
    config.file_suffix = "Api.ts"
    config.client_library = "@js-from-routes/inertia"
    config.helper_mappings = {"index" => "index", "show" => "show"}
  end
end
