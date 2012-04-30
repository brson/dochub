module Views
  class Page < Layout
    attr_reader :page, :user, :repo

    def needs_header
      @page.title == @page.name
    end

    def name
      @page.name
    end

    def title
      @page.title
    end

    def content
      @page.formatted_data
    end

    def format
      @page.format.to_s
    end

    def has_sidebar
      @sidebar = (@page.sidebar || false) if @sidebar.nil?
      !!@sidebar
    end

    def sidebar_content
      has_sidebar && @sidebar.formatted_data
    end

    def sidebar_format
      has_sidebar && @sidebar.format.to_s
    end

    def has_footer
      @footer = (@page.footer || false) if @footer.nil?
      !!@footer
    end

    def footer_content
      has_footer && @footer.formatted_data
    end

    def footer_format
      has_footer && @footer.format.to_s
    end

  end
end
