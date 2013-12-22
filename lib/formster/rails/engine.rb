module Formster
  module Rails
    class Engine < ::Rails::Engine
      initializer "formster.helpers" do
        ActionView::Base.send :include, Formster::Helper
      end
    end
  end
end