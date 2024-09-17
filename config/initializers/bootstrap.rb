ActionView::Base.field_error_proc = proc do |html_tag, instance|
  html_doc = Nokogiri::HTML::DocumentFragment.parse(html_tag, Encoding::UTF_8.to_s)
  element = html_doc.children[0]

  if element
    element.add_class("is-invalid")

    if %w[input select textarea].include? element.name
      failing_field_name = instance.instance_variable_get("@sanitized_method_name")
      errors = instance.object.errors.full_messages_for(failing_field_name)

      instance.raw %(#{html_doc.to_html} <div class="invalid-feedback">#{errors.join('<br>'.html_safe)}</div>)
    else
      instance.raw html_doc.to_html
    end
  else
    html_tag
  end
end
