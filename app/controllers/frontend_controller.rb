# frozen_string_literal: true

class FrontendController < ApplicationController
  def show
    render file: Rails.root.join("public", "frontend", "index.html"), layout: false
  end
end
