module Views
  class Page < Layout
    attr_reader :page, :name

    def content
      @page.formatted_data
    end

    def has_sidebar
      @sidebar = (@page.sidebar || false) if @sidebar.nil?
      !!@sidebar
    end

    def sidebar_content
      has_sidebar && @sidebar.formatted_data
    end

  end
end
