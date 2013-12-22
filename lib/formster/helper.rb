module Formster
  module Helper
    # def buttons(options = {})
    #   options[:show] ||= [ :ok, :cancel ]
    #   options[:ok] ||= "Save"
    #   options[:cancel] ||= "Cancel"

    #   if options[:cancel_url]
    #     cancel_js = "window.location='#{options[:cancel_url]}';"
    #   else
    #     cancel_js = "history.go(-1);"
    #   end

    #   out  = "<div class='buttons'>\n"
    #   for button in options[:show]
    #     case button
    #     when :ok
    #       out << " <input type='submit' class='ok' value='#{options[:ok]}' />\n"
    #     when :cancel
    #       out << " <input type='button' class='cancel' value='#{options[:cancel]}' onclick=\"#{cancel_js}\" />\n"
    #     when :reset
    #       out << " <input type='reset' class='reset' value='#{options[:reset]}' />\n"
    #     end
    #   end
    #   out += "</div>\n"
    #   out.html_safe
    # end

    def formster_for(record_or_name_or_array, *args, &proc)
      args.push({}) unless args.last.is_a?(Hash)
      
      options = args.last
      form_type = options.delete(:form_type) || :default
      args.last[:builder] = FORMSTER_FORM_BUILDERS[form_type]
      
      form_for(record_or_name_or_array, *args, &proc)
    end

    class BaseFormBuilder < ::ActionView::Helpers::FormBuilder
      @@helpers = []
      @@subclasses = []

      def self.register_field_helper(method, meta)
        @@helpers.push([method, meta])
        @@subclasses.each do |sc|
          sc.define_field_helper(method, meta)
        end
      end

      def self.inherited(subclass)
        @@helpers.each do |helper|
          subclass.define_field_helper(helper[0], helper[1])
        end
        @@subclasses << subclass
      end

      def initialize(object_name, object, template, options, &proc)
        html_options = (options[:html] ||= {})
        html_options[:class] ||= ''
        html_options[:class] << " #{form_class}"
        super
      end
      
      def form_class
        ''
      end

      def submit(value = nil, options = {})
        if value.is_a?(Hash)
          options = value
          value = nil
        end
        options[:class] = "btn #{options[:class] || 'btn-default'}"
        super(value, options)
      end
    end

    class DefaultFormBuilder < BaseFormBuilder
      
      def self.define_field_helper(helper, meta)

        option_arg_position   = meta[0]
        archetype             = meta[1]

        helper_code = <<-CODE
          alias naked_#{helper} #{helper}

          def #{helper}(*args, &block)
            options = (args[#{option_arg_position}] ||= {})
        CODE

        case archetype
        when :input, :textarea, :select, :file
          helper_code << <<-CODE

              lbl = if options.key?(:label)
                      options.delete(:label)
                    else
                      true
                    end

              lbl = args[0].to_s.humanize if lbl === true

              help = options.delete(:help_block)

              options[:class] ||= ''
              options[:class] << ' form-control'

              html  = "<div class='form-group'>"
              html << label(args[0], lbl) if lbl
              html << naked_#{helper}(*args, &block)
              html << "<p class='help-block'>\#{help}</p>" if help
              html << "</div>"
          CODE
        when :checkbox
          helper_code << <<-CODE
              lbl = options.delete(:label) || args[0].to_s.humanize

              if options.delete(:inline)
                html << "<label class='checkbox-inline'>"
                html << naked_#{helper}(*args, &block)
                html << lbl
                html << "</label>"
              else
                html  = "<div class='checkbox'>"
                html << "  <label>"
                html << naked_#{helper}(*args, &block)
                html << lbl
                html << "  </label>"
                html << "</div>"
              end
          CODE
        when :radio
          helper_code << <<-CODE
              lbl = options.delete(:label) || args[0].to_s.humanize

              if options.delete(:inline)
                html << "<label class='radio-inline'>"
                html << naked_#{helper}(*args, &block)
                html << lbl
                html << "</label>"
              else
                html  = "<div class='radio'>"
                html << "  <label>"
                html << naked_#{helper}(*args, &block)
                html << lbl
                html << "  </label>"
                html << "</div>"
              end
          CODE
        end

        helper_code << <<-CODE
            html.html_safe
          end
        CODE

        class_eval helper_code
      end
      
      # def fieldset(title = '', &block)
      #   html  = "<fieldset>"
      #   html << @template.content_tag(:legend, title) if title
      #   html << "<ol>"
      #   html << @template.capture(&block) if block_given?
      #   html << "</ol>"
      #   html << "</fieldset>"
      #   html.html_safe
      # end
      
      # def item(options = {}, &block)
      #   html  = "<li>\n"
      #   html << "  <label>#{options[:label]}</label>\n" if options[:label]
      #   html << "  <div class='form-input'>\n"
      #   html << @template.capture(&block) if block_given?
      #   html << "    <p class='note'>#{options[:note]}</p>\n" if options[:note]
      #   html << "  </div>\n"
      #   html << "</li>\n"
      #   html.html_safe
      # end
      
      # def buttons
      #   @template.buttons
      # end
    end

    class InlineFormBuilder < DefaultFormBuilder
      def form_class
        'form-inline'
      end
    end

    class HorizontalFormBuilder < DefaultFormBuilder
      def form_class
        'form-horizontal'
      end
    end

    FORMSTER_FORM_BUILDERS = {
      :default      => DefaultFormBuilder,
      :inline       => InlineFormBuilder,
      :horizontal   => HorizontalFormBuilder
    }

    { :check_box                  => [1, :checkbox],
      :color_field                => [1, :input],
      :date_field                 => [1, :input],
      :datetime_field             => [1, :input],
      :datetime_local_field       => [1, :input],
      :email_field                => [1, :input],
      :file_field                 => [1, :file],
      :month_field                => [1, :input],
      :number_field               => [1, :input],
      :password_field             => [1, :input],
      :phone_field                => [1, :input],
      :radio_button               => [2, :radio],
      :range_field                => [1, :input],
      :search_field               => [1, :input],
      :telephone_field            => [1, :input],
      :text_area                  => [1, :textarea],
      :text_field                 => [1, :input],
      :time_field                 => [1, :input],
      :url_field                  => [1, :input],
      :week_field                 => [1, :input],

      :select                     => [4, :select],
      :collection_select          => [4, :select],
      :date_select                => [1, :select],
      :datetime_select            => [1, :select],
      :grouped_collection_select  => [6, :select],
      :time_select                => [1, :select]
    }.each do |method, meta|
      BaseFormBuilder.register_field_helper(method, meta)
    end
  
  end
end