module Jekyll
  module FancyToCFilter
    def fancytoc(input)
      converter = Redcarpet::Markdown.new(Redcarpet::Render::HTML_TOC, :no_intra_emphasis => true, :fenced_code_blocks => true, :autolink => true, :strikethrough => true, :superscript => true)
      converter.render(input)
    end
  end
end

Liquid::Template.register_filter(Jekyll::FancyToCFilter)
