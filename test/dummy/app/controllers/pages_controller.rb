# frozen_string_literal: true

class PagesController < ApplicationController
  def show
    render plain: "Welcome"
  end
end
