# encoding: UTF-8

require 'selenium-webdriver'
require 'test-unit'
require 'shoulda-context'
#SelWeT (Selenium Web Test) - гем для веб тестирования.
module SelWeT
#Класс Unit содержит необходимый набор методов для взаимодействия с браузером.
#Тесты пишутся с использованием shoulda-context.
#@example
#        #!/usr/bin/env ruby
#        # encoding: UTF-8
#        require 'selwet'
# 
#        class SelWeT::Unit
#   
#          set_browser :firefox
#          set_selenium_server_url 'http://127.0.0.1:4444/wd/hub'
#   
#          context "Example" do
#
#            should "open page 'About Us'" do
#              Unit.go_to "http://inventos.ru/"
#              Unit.click '#menu-item-3795 a'
#              current_location = Unit.get_location
#              assert_equal 'http://inventos.ru/about/#top', current_location, 'Invalid location!'
#            end
# 
#          end
#
#        end
  class Unit < Test::Unit::TestCase

    include SelWeT

    private
    
      @@server_url = nil
      @@timewait = 5
	  @@pageload_timewait = 5
      @@browser = nil
      @@handles = {}
      
    class Error < RuntimeError
    end
    
    class ArgumentValueError < Error
    end
    
    class ElementIsMissingError < Error
    end

    class ConnectionRefusedError < Error
    end

    class PageLoadError < Error
    end

    class ElementIsNotDisplayedError < Error
    end

    class << self
#Кликает на кнопку 'Cancel' в окне алерта.
#@example
#       class SelWeT::Unit
#   
#          ...
#   
#          context "Example" do
#     
#            should "TODO something" do
#              ...
#              Unit.alert_cancel
#          ...
#@see click
#@see alert_ok 
      def alert_cancel
        @@driver.switch_to.alert.dismiss
      end
#Кликает на кнопку 'Ok' в окне алерта.
#@example
#       class SelWeT::Unit
#   
#          ...
#   
#          context "Example" do
#     
#            should "TODO something" do
#              ...
#              Unit.alert_ok
#          ...
#@see click
#@see alert_cancel 
      def alert_ok
        @@driver.switch_to.alert.accept
      end
#Возвращает состояние для radio и checkbox.
# @param selector [String] css селектор
# @return [FalseClass/TrueClass] checked ~ true, unchecked ~ false
#@example
#       class SelWeT::Unit
#   
#         ...
#   
#          context "Example" do
#     
#            should 'TODO something' do
#              Unit.go_to 'http://some_page.com/
#              ...
#              status = Unit.checked?(#my_checkbox_id')
#          ...
      def checked? selector
        raise(ArgumentValueError, "Invalid value of argument 'selector'") unless selector.class == String
        if check_element(selector) 
          element = @@driver.find_element(:css => selector)
          raise "Element #{selector} is not a checkbox/radio" unless ['radio', 'checkbox'].include?(element.tag_name)
          raise "Element #{selector} not displayed" unless element.displayed?
          return element.selected?.inspect
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end
      end
#Проверяет наличие элемента на странице. Если нужно получить количество элементов, то в качестве второго аргумента следует передать true.
#@param selector [String] css селектор элемент
#@param num [FalseClass/TrueClass]
#@return [FalseClass/TrueClass, Fixnum] первое значение - результат проверки наличия элемента, второе - число элементов (возвращается, если агрумент num имеет значение true)
#@example 
#       context "Example" do
#  
#         should "TODO something" do
#           ...
#           assert_equal true, Unit.check_element 'a.menu'
#         end
#           ...   
      def check_element selector, num = nil
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        raise(ArgumentValueError, "Invalid value \"#{num}\" of argument 'num'") unless [FalseClass, TrueClass, NilClass].include?(num.class)
        wait = Selenium::WebDriver::Wait.new(:timeout => @@timewait)
        begin
          wait.until { @@driver.find_element(:css => selector) }
        rescue Selenium::WebDriver::Error::TimeOutError
          return false
        end
        if num
          return true, @@driver.find_elements(:css => selector).size
        else
          return true
        end
      end
#Очистить кэш браузера
      def clear_cache
        @@driver.manage.delete_all_cookies
      end
#Кликнуть на элемент.
#@param selector [String] css селектор элемента
#@example
#       context "Example" do
#     
#         should "TODO something" do
#           ...
#           Unit.click 'input[type="submit"]'
#         ...
#@see alert_ok
#@see alert_cancel
 

def click selector, desc = nil
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        raise(ArgumentValueError, "Invalid value \"#{desc}\" of  argument 'desc'") unless [String, NilClass].include?(desc.class)
        i = 0
            if (check_element(selector))
                begin    
                    element = @@driver.find_element(:css => selector)
                    raise(ElementIsNotDisplayedError, "Element \"#{selector}\" is not displayed") unless displayed?(selector)
                    element.click
                    if (@@browser == :chrome)
                        sleep 1
                    end
                    wait = Selenium::WebDriver::Wait.new
                    wait.until { @@driver.execute_script("return window.onunload = function(){return window.onload}; ") }
                rescue ElementIsNotDisplayedError
                    i = i + 1
                    if i <= 2 
                        sleep @@timewait
                        retry
                    else
                        raise(ElementIsNotDisplayedError, "Element \"#{selector}\" is not displayed") unless displayed?(selector)
                end
            end
         end
      end


#Закрыть окно с номером num. Окна нумируются в порядке их открытия. Нумирация начинается с 0. Если необходимо закрыть текущее окно, то перед закрытием необходимо переключиться на другое окно. После закрытия окна происходить их переупорядочивание. Так, например, если было закрыто первое окно (num = 0), то второе окно станет первым (было num = 1, стало num = 0) и т.д.
#@param num [Fixnum] номер окна
#@example
#       context "Example" do
#            
#         should 'TODO something' do
#           Unit.close_window 2
#           ... 
#@see switch_to_window
      def close_window num
        raise ArgumentError.new("Invalid value \"#{num}\" of argument 'num'") unless num.class == Fixnum
        update_window_handles
        raise 'Invalid window number' unless @@handles.keys.include?(num.to_s)
        current = @@handles.key(@@driver.window_handle)
        raise 'Can not close active window' if num.to_s == current
        @@driver.switch_to.window @@handles[num.to_s]
        @@driver.close
        @@handles.delete_if { |key, value| key == num.to_s }
        @@driver.switch_to.window @@handles[current]
        new_handles = {}
        num = 0
        @@handles.keys.sort.each do |key|
          new_handles[num.to_s] = @@handles[key]
          num += 1
        end
        @@handles = new_handles
      end
#Проверяет, отображается ли элемент странице.
#@param selector [String] css селектор элемента
#@return [FalseClass/TrueClass]
#@example 
#       context "Example" do
#  
#         should "TODO something" do
#           ...
#           assert_equal true, Unit.displayed? '.menu'
#         end
#           ...   
      def displayed? selector
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        if check_element(selector)
          return @@driver.find_element(:css => selector).displayed?
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end
      end
#Заполнить поле или выбирает файл для загрузки.
# @param selector [String] css селектор
# @param value [String] значение, которое необходимо ввести
#@example
#       context "Example" do
#     
#         should 'TODO something' do
#           Unit.go_to @@somePage
#           ...
#           Unit.fill_in 'input#some_id', 'some text' #заполнить текстовое поле
#           Unit.fill_in 'input#[type={"file"}]', '/path/to/file' #выбрать файл для загрузки
#       ...
      def fill_in selector, value
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        raise(ArgumentValueError, "Invalid value \"#{value}\" of argument 'value'") unless value.class == String
        i = 0
        if check_element(selector)
            begin
                element = @@driver.find_element(:css => selector)
                raise(ElementIsNotDisplayedError, "Element \"#{selector}\" is not displayed") unless displayed?(selector)
                begin
                    @@driver.action.move_to(element).perform
                    element.clear
                rescue
            #skip this
                end
                element.send_keys(value)
            rescue ElementIsNotDisplayedError
                i = i + 1
                if i <= 2
                    sleep @@timewait
                    retry
                else
                    raise(ElementIsNotDisplayedError, "Element \"#{selector}\" is not displayed") unless displayed?(selector)
                end
            end
        
        else
            raise(ElementIsMissingError, "Element #{selector} is missing")
        end      
      end
#Навести курсор на элемент.
#@param selector [String] css селектор
#       @example
#       context "Example" do
#     
#         should 'TODO somethin' do
#           Unit.hover_over_element "div.menu"
#           Unit.click "a.some_url"
#           ...
      def hover_over_element selector
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        if check_element(selector)
          element = @@driver.find_element(:css => selector)
          @@driver.action.move_to(element).perform
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end
      end
#Получить значение атрибута элемента.
#@param selector [String] css селектор элемента
#@param attr [String] атрибут
#@param all [Boolean] Указывает, надо ли вернуть все найденные элементы, соответствующие selector. По умлочанию - nil. 
#@return [String/Array] значение атрибута (при all == false) или набор атрибутов (при all == true)
#@example
#       context "Example" do
#     
#         should 'TODO somethin' do
#           link = Unit.get_attr "a.class", 'href'
#           ...
#           all_links = Unit.get_arrt "a.class", 'href', true
#           ...

      def get_attr selector, attr, all = nil
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        raise(ArgumentValueError, "Invalid value \"#{attr}\" of argument 'attr'") unless attr.class == String
        if check_element(selector)
          unless all
            return @@driver.find_element(:css => selector).attribute(attr)
          else
            elems = @@driver.find_elements(:css => selector)
            array = []
            elems.each do |elem|
              array.push elem.attribute(attr)
            end
            return array
          end
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end
      end
#Получить открытый URL текущего окна.
#@return [String] URL
#@example
#       context "Example" do
#     
#         should 'TODO somethin' do
#           current_location = Unit.get_location
#           ...
      def get_location
        @@driver.current_url
      end
#Получить тег элемента.
#@param selector [String] css селектор элемента
#@param all [Boolean] Указывает, надо ли вернуть все найденные элементы, соответствующие selector. По умлочанию - nil.
#@return [String/Array] тег (при all == false) или набор тегов (при all == true)
#@example
#       context "Example" do
#     
#         should 'TODO somethin' do
#          tag_name = Unit.get_tag '.element_class'
#          ...
#          all_tags = Unit.get_tag '.element_class', true
#          ...
      def get_tag selector, all = nil
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        if check_element(selector)
          unless all
            return @@driver.find_element(:css => selector).tag_name
          else
            elems = @@driver.find_elements(:css => selector)
            array = []
            elems.each do |elem|
              array.push elem.tag_name
            end
            return array    
          end
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end
      end
#Получить текст, отображаемый на элементе или группе элементов.
#@param selector [String] css селектор элемента
#@param all [String] установить true, если необходимо получить текст для группы элементов
#@return [String/Array] текст, или массив строк, если all установлен как true
#@example
#       context "Example" do
#     
#         should 'TODO somethin' do
#           text = Unit.get_text 'div.element_class'
#           text = Unit.get_text('div.other_class', true)
#           ...
      def get_text selector, all = nil
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        raise(ArgumentValueError, "Invalid value \"#{all}\" of argument 'all'") unless [NilClass, FalseClass, TrueClass].include?(all.class)
        if check_element(selector)
          unless all
            return @@driver.find_element(:css => selector).text
          else
            elems = @@driver.find_elements(:css => selector)
            array = []
            elems.each do |elem|
              array.push elem.text
            end
            return array
          end
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end
      end
#Переход по ссылке. При переходе функция дожидается полной загрузки страницы в пределах времени pageload_timeout.
#@param url [String] ссылка, по которой необходимо перейти.
#@example
#       context "Example" do
#     
#         setup do
#           Unit.go_to @@somePage
#         end
#         ...
#@see refresh
      def go_to url
        raise(ArgumentValueError, "Invalid value of argument 'selector'") unless url.class == String
        wait = Selenium::WebDriver::Wait.new
        i = 0
        begin            
            @@driver.navigate.to url
            if (@@browser == :chrome)
                sleep 1
            end
            wait.until { @@driver.execute_script("return window.onload = function(){}; ") }
            i = i + 1 
        rescue Exception => e 
            if i <= 2 
                @@driver.navigate.refresh
                retry
            else 
                raise(PageLoadError, "Page #{url} didn't load within PageLoadTimeOut time")
            end
        end
    end
#Проверяет, открыто ли окно с номером num.
#@param num [Fixnum] номер окна
#@return [FalseClass/TrueClass]
#@example
#       context "Example" do
#     
#         should 'TODO somethin' do
#           ...
#           assert_equal false, Unit.opened?(2), 'Window not closed!'
      def opened? num
        raise(ArgumentValueError, "Invalid value of argument 'num'") unless num.class == Fixnum
        update_window_handles
        return @@handles.keys.include?(num.to_s)
      end
#Нажать клавишу на клавиатуре. Для клавиш, отличных от алфовитно-цифровых, в качестве параметра следует передавать значение типа Symbol, соответствующее необходимой клавише. Допустимые значения: :cancel,:help,:backspace,:tab,:clear,:return,:enter,:shift,:left_shift,:control,:left_control,
#:alt,:left_alt,:pause,:escape,:space,:page_up,:page_down,:end,:home,:left,:arrow_left,:up,:arrow_up,
#:right,:arrow_right,:down,:arrow_down,:insert,:delete,:semicolon,:equals,:numpad0,:numpad1,:numpad2,
#:numpad3,:numpad4,:numpad5,:numpad6,:numpad7,:numpad8,:numpad9,:multiply,:add,:separator,:subtract,
#:decimal,:divide,:f1,:f2,:f3,:f4,:f5,:f6,:f7,:f8,:f9,:f10,:f11,:f12,:meta,:command
#@param key [String/Symbol] клавиша
#@param state [Symbol] состояние. Допустимые значения: :down(нажать), :up(отпустить). Если параметр не будет указан, то будет сделано обычное нажатие.
      def press_key key, state = nil
        unless [
                :null,:cancel,:help,:backspace,:tab,:clear,:return,:enter,:shift,:left_shift,:control,:left_control,
                :alt,:left_alt,:pause,:escape,:space,:page_up,:page_down,:end,:home,:left,:arrow_left,:up,:arrow_up,
                :right,:arrow_right,:down,:arrow_down,:insert,:delete,:semicolon,:equals,:numpad0,:numpad1,:numpad2,
                :numpad3,:numpad4,:numpad5,:numpad6,:numpad7,:numpad8,:numpad9,:multiply,:add,:separator,:subtract,
                :decimal,:divide,:f1,:f2,:f3,:f4,:f5,:f6,:f7,:f8,:f9,:f10,:f11,:f12,:meta,:command
               ].include? key
          raise(ArgumentValueError, "Invalid value \"#{key}\" of argument 'key'") unless /^[A-Za-z0-9]$/ === key.to_s
        end
        raise(ArgumentValueError, "Invalid value \"#{state}\" of argument 'state'") unless [:up, :down, nil].include?(state)
        case state
        when :up
          @@driver.action.key_up(key).perform
        when :down
          @@driver.action.key_down(key).perform
        when nil
          @@driver.action.send_keys(key).perform
        end
      end
#Обновить текущее окно
      def refresh
        @@driver.navigate.refresh
      end
#Сделать скриншот. Файл будет сохранен в каталоге, из которого был произведен запуск теста с расширением .png.
#@param filename [String] имя файла
      def screenshot filename
        raise(ArgumentValueError, "Invalid value \"#{filename}\" of argument 'filename'") unless filename.class == String
        @@driver.save_screenshot("./"+filename+".png") 
      end
#Устанавливает используемый для тестирования браузер. Необходимо использовать перед блоками тестов.
#@param browser [Symbol] браузер. Допустимые значения: :firefox, :chrome, :ie, :safari, :phantomjs.
#@example
#       class SelWeT::Unit
#               set_browser :firefox
#               ...
      def set_browser browser
        raise(ArgumentValueError, "Invalid value \"#{browser}\" of argument 'browser'") unless [:firefox, :chrome, :ie, :safari, :phantomjs].include? browser
        @@browser = browser
      end
#Выбирает элементы в select по индексам. Нумирация начинается с 0. Если в multiple select необходимо выбрать несколько элементов, то нужно передать массив индексов. 
#@param selector [String] css селектор
#@param items [Fixnum/Array] индекс или массив индексов элементов, которые необходимо выбрать
#@example
#          context "Example" do
#     
#            should "TODO something" do
#              Unit.set_select_items 'select[name="some_name"]', 2
#              Unit.set_select_items 'select[name="other_name"]', [1,3,6]
#          ...   
      def set_select_items selector, items
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        raise(ArgumentValueError, "Invalid value \"#{items}\" of argument 'items'") unless [Array, Fixnum].include?(items.class)
        if check_element(selector)
          select = Selenium::WebDriver::Support::Select.new(@@driver.find_element(:css => selector))
          raise(ArgumentValueError, "Invalid value \"#{items}\" of argument 'items' for not multiple select") if items.class == Array and !select.multiple?
          if select.multiple?
            select.deselect_all
            if items.class == Array
              items.each do |item|
                raise(ArgumentValueError, "Invalid value \"#{items}\" of argument 'items'") unless item.class == Fixnum
                select.select_by(:index, item)
              end
            else
              select.select_by(:index, items)
            end
          else
            select.select_by(:index, items)
          end
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end 
      end
#Устанавливает URL для Selenium Server или PhantomJS. Необходимо использовать перед блоками тестов.
#Если параметр не указан, то будет использован локальный браузер
#@param url [String] URL запущенного Selenium Server
#@example
#       class SelWeT::Unit
#               set_browser :firefox
#               set_server_url "http://somewhere:4444/wd/hub"
#               ...
      def set_server_url url
        raise(ArgumentValueError, "Invalid value \"#{url}\" of argument 'url'") unless url.class == String
        @@server_url = url
      end
#Устанавливает максимально допустимое время ожидания элемента (по умолчанию 5 секунд). Необходимо использовать перед блоками тестов.
#@param sec [Fixnum] время в секундах.
#@example
#       class SelWeT::Unit
#               set_browser :firefox
#               set_timewait 15
#               ...
#@see set_pageload_timewait
      def set_timewait sec
        raise(ArgumentValueError, "Invalid value \"#{sec}\" of argument 'sec'") unless sec.class == Fixnum
        @@timewait = sec
      end
#Устанавливает максимально допустимое время ожидания загрузки страницы(по умолчанию 5 секунд). Может отличаться от времени ожидания элементов. Необходимо использовать перед блоками тестов.
#@param sec [Fixnum] время в секундах.
#@example
#       class SelWeT::Unit
#               set_browser :firefox
#               set_timewait 3
#               set_pageload_timewait 15
#               ...
#@see set_timewait
      def set_pageload_timewait sec
        raise(ArgumentValueError, "Invalid value \"#{sec}\" of argument 'sec'") unless sec.class == Fixnum
        @@pageload_timewait = sec
      end

#Закрывает браузер после выполнения всех тестов.
#Внутренний метод. Выполняется автоматически.    
      def shutdown
        if @@driver
          @@driver.close
          @@driver.quit
        end
      end
#Запускает браузер перед выполнением тестов.
#Выполняется автоматически непосредственно перед запуском тестов.
      def startup
        begin
            @@driver = nil
            url = nil
            unless @@server_url
                puts 'URL not specified! Local browser will be used.'
            else
                url = @@server_url
            end
            if @@browser.nil?
                raise ArgumentError.new('Browser not specified!')
            end
            if url
                if @@browser == :phantomjs
                    @@driver = Selenium::WebDriver.for(:remote, :url => url)
                else
                    @@driver = Selenium::WebDriver.for(:remote, :desired_capabilities => @@browser, :url => url)
                end
            else
                @@driver = Selenium::WebDriver.for @@browser
            end

            if (@@driver == nil)
                raise("Can't create driver for #{@@browser.to_s}")
            end

        rescue Errno::ECONNREFUSED
            raise(ConnectionRefusedError, "Connection refused on #{@@server_url}\n\n") 
        end

        @@driver.manage.timeouts.implicit_wait = @@timewait
        @@driver.manage.timeouts.script_timeout = @@timewait
        @@driver.manage.timeouts.page_load = @@pageload_timewait
        @@driver.manage.window.maximize
        @@handles["0"] = @@driver.window_handle
      end
#Переключиться на другое окно. Окна нумируются в порядке их открытия. Нумирация начинается с 0.
#@param num [Integer] номер окна.
#@example
#          context "Example" do
#     
#            should 'TODO something' do
#              ...
#              Unit.switch_to_window 0
#              Unit.close_window 1
#              ... 
#@see close_window
      def switch_to_window num
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'num'") unless num.class == Fixnum
        update_window_handles
        raise "Invalid window number" unless @@handles.keys.include?(num.to_s)
        @@driver.switch_to.window @@handles[num.to_s]
      end
#Переключиться на iframe. Для дальнейшего взаимодействия с основной страницей необходимо выполнить {to_page}.
#@param selector [String] css селектор на iframe
#@example
#        ...   
#          context "Example" do
#     
#            should 'show popup' do
#              Unit.to_frame 'iframe#frame1'
#          ...
#@see to_page
      def to_frame selector
        raise(ArgumentValueError, "Invalid value \"#{selector}\" of argument 'selector'") unless selector.class == String
        if check_element(selector)
          element = @@driver.find_element(:css => selector)
          @@driver.action.move_to(element).perform
          @@driver.switch_to.frame element
        else
          raise(ElementIsMissingError, "Element #{selector} is missing")
        end
      end
#Переключиться на основную страницу.
#@example
#         ...
#          context "Example" do
#     
#            should 'Show popup' do
#              ...
#              Unit.to_page
#          ...
#@see to_frame
      def to_page
        @@driver.switch_to.default_content 
      end
#Обновить список handle. Внутренняя функция.
      def update_window_handles
        new_handles = @@driver.window_handles - @@handles.values
        old_handles = @@handles.values - @@driver.window_handles
        @@handles.delete_if{ |key, value| old_handles.include? value }
        unless new_handles.empty?
          num = @@handles.keys.max.to_i+1
          new_handles.each do |handle|
            @@handles[num.to_s] = handle
            num += 1
          end
        end
      end
#Получить залоговок текущего окна.
#@return [String] заголовок
      def window_title
        @@driver.title
      end

    end

  end

end
