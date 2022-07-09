# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Internal: Render an Inertia page that matches the current controller and action.
  def render_page(**props)
    render inertia: "#{controller_name}/#{action_name}", props: props
  end
end
