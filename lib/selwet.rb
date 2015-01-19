# encoding: UTF-8

require 'selenium-webdriver'
require 'test-unit'
require 'shoulda-context'
#Модуль SelWeT (Selenium Web Test) позволяет тестировать веб-страницы в одном, или нескольких браузерах. Если тестирование производится в нескольких браузерах, то оно проводится параллельно.
module SelWeT
#Класс Unit содержит методы для проверки элементов страницы, получения их текстового содержимого и значения поля href для ссылок, заполнения полей,  select-ов и форм, указания файлов для загрузки, кликов по элементам и кнопкам алерта, проверки статуса для radio и checkbox, перехода на другую страницу, обновления страницы, проверки текущего URL, открытие ссылки в новом окне, смены и закрытия окна, создания скриншотов.
#
#Тесты пишутся с использованием shoulda-context.
#@example
#        #!/usr/bin/env ruby
#        # encoding: UTF-8
#        require 'selwet'
# 
#        class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://127.0.0.1:4444/wd/hub'
#   
#          context "Example" do
#            should "About Us" do
#              Unit.go_to "http://inventos.ru/"
#              Unit.click '#menu-item-3795 a'
#              status, error = Unit.check_location 'http://inventos.ru/about/#top'
#              assert_equal true, status, error
#            end
#          end
#
#        end
class Unit < Test::Unit::TestCase
  include SelWeT
  private
    @@url_selenium = nil
    @@start_url = nil
    @@browsers = nil
    @@opened_window = {}
    @@win_num = 0
    
  class << self
#Запускает браузеры перед выполнением тестов.
#Выполняется автоматически непосредственно перед запуском тестов.
    def startup
      @@driver = {}
      url = nil
      unless @@url_selenium
        puts 'URL for selenium server not specified!'
        exit 1
      else
        url = @@url_selenium
      end
      if @@browsers.nil?
        puts 'Browsers not specified!'
        exit 1
      end
      begin
        @@browsers.each do |browser|
          if [:firefox, :chrome, :ie, :safari].include? browser
            @@driver[browser.to_s] = Selenium::WebDriver.for(:remote, :desired_capabilities => browser, :url => url)
            @@driver[browser.to_s].manage.timeouts.implicit_wait = 15
            @@driver[browser.to_s].manage.timeouts.script_timeout = 15
            @@driver[browser.to_s].manage.timeouts.page_load = 15
            @@driver[browser.to_s].manage.window.maximize
          else
            puts "Bad browser #{browser}"
          end
        end
      rescue Exception => e
        puts "ERROR: #{e.to_s}"
        exit 1
      end
      if @@start_url
        go_to @@start_url
      end
    end 
#Закрывает все используемые браузеры после выполнения всех тестов.
#Выполняется автоматически.    
    def shutdown
      @@driver.each do |name, driver|
        begin
          driver.close
          driver.quit
        rescue
          puts 'Browser '+name+' not closed ...' 
        end
      end
    end
#Устанавливает URL Selenium Server. Необходимо использовать перед блоками тестов.
#
#@param url [String] URL запущенного Selenium Server
#@example
#       class SelWeT::Unit
#               set_browsers [:firefox, :chrome]
#               set_selenium_server_url "http://localhost:4444/wd/hub"
#               ...
    def set_selenium_server_url url 
      @@url_selenium = url
    end
#Устанавливает стартовую страницу при запуске браузеров. Использовать только перед блоками тестов.
#@param url [String] URL тестируемого сайта
#@example
#       class SelWeT::Unit
#               set_browsers [:firefox, :chrome]
#               set_selenium_server_url "http://localhost:4444/wd/hub"
#               open_link "http://inventos.ru/"
#               ...
    def open_link url
      @@start_url = url
    end
#Устанавливает используемые для тестирования браузеры. Необходимо использовать перед блоками тестов.
#@param params [Array] массив, содержащий одно или несколько из следующий значений: :firefox, :chrome, :ie, :safari. Для :chrome и :ie Selenium Server следует запускать с соответствующими драйверами.
#@example
#       class SelWeT::Unit
#               set_browsers [:firefox, :chrome]
#               ...
    def set_browsers params 
      @@browsers = params
    end
#Переход по ссылке. Используется только в блоках should или setup
#@param url [String] ссылка, по которой необходимо перейти.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://inventos.ru/produkty/#top'
#   
#          context "Example" do
#     
#            setup do
#              Unit.go_to @@somePage
#            end
#          ...
#@see refresh
    def go_to url
      threads = []
      @@driver.each do |name, driver|
        threads << Thread.new do
          driver.navigate.to url
        end
      end
      threads.each(&:join)
    end
#Переключиться на iframe. Используется только в блоках should или setup. Для дальнейшего взаимодействия с основной страницей необходимо выполнить {to_page}.
#@param selector [String] css селектор на нужный iframe.
#@example
#       class SelWeT::Unit
#   
#         ...
#   
#          context "Example" do
#     
#            should 'Show popup' do
#              Unit.to_frame 'iframe#frame1'
#          ...
#@see to_page
    def to_frame selector
      threads = []
      status, message, tags = get_tag selector
      unless status
        return false, "to_frame: "+message
      end
      bad_values = []
      tags.each do |name, tag|
        if tag != 'iframe'
          bad_values << name +" : "+tag
        end
      end
      if bad_values.size != 0
        return false, "to_frame: #{bad_values.join(", ")} - It is not 'iframe'! "
      end
      @@driver.each do |name, driver|
        threads << Thread.new do
          element = driver.find_element(:css => selector)
          driver.action.move_to(element).perform
          driver.switch_to.frame element
        end
      end
      threads.each(&:join)
      return true
    end
#Очистить кэш браузера
#@example
#       class SelWeT::Unit
#   
#         ...
#   
#          context "Example" do
#     
#            should 'Do something' do
#              ...
#              Unit.clear_cache
#          ...
  def clear_cache
    threads = []
    @@driver.each do |name, driver|
      threads << Thread.new do
        driver.manage.delete_all_cookies
      end
    end
    threads.each(&:join)
  end
#Переключиться на основную страницу. Используется только в блоках should или setup.
#@example
#       class SelWeT::Unit
#   
#         ...
#   
#          context "Example" do
#     
#            should 'Show popup' do
#              ...
#              Unit.to_page
#          ...
#@see to_frame
    def to_page
      threads = []
      @@driver.each do |name, driver|
        threads << Thread.new do
          driver.switch_to.default_content
        end
      end
      threads.each(&:join)
    end    
#Выбирает элементы в select. Используется только в блоках should или setup. Работает как с обычными select, так и с select с множественным выбором. Если для select с множественным выбором не указать аргумент items, то выделение будет снято со всех option.
# @param selector [String] css селектор select.
# @param items [Array] массив значений, которые необходимо выбрать.
#@example
#       class SelWeT::Unit
#   
#          ...
#   
#          context "Example" do
#     
#            should "TODO something" do
#              Unit.set_select_items 'select[name="some_name"]', ['value 1', 'value2']
#          ...    
    def set_select_items selector, items = nil
        threads = []
        status = true
        errors = []
        @@driver.each do |name, driver|
          threads << Thread.new do
            thread_status = true
            begin
              element = driver.find_element(:css => selector)
            rescue Exception => e
              errors << name+' : Bad selector : '+selector
              thread_status = false
              status = false
            end
            if thread_status
              unless element.tag_name == 'select'
                status = false
                errors << "#{name} - set_select_items using only for select!"
              else
                option = Selenium::WebDriver::Support::Select.new(element)
                if option.multiple?
                  option.deselect_all 
                  if items
                    options = element.find_elements(:css => 'option')
                    options.each do |item|
                      if items.include? item.text
                        items.delete item.text
                        driver.action.key_down(:shift).click(item).key_up(:shift).perform
                      end
                    end
                    if items.size > 0
                      status = false
                      errors << "set_select_items: Some passed option values were not found (#{name}): "+items.join(' ')
                    end
                  end
                else
                  if items
                    if items.size == 1
                      begin
                        option.select_by(:text, items[0])
                      rescue
                        status = false
                        errors << "set_select_items: Option '#{items}' does not exist!"
                      end
                    else
                      status = false
                      errors << "set_select_items: '#{selector}' is not multiple! You must pass a single value."
                    end
                  end
                end
              end
            end
          end
        end
        threads.each(&:join)
        return [status, errors.uniq.join("\n")]
    end
#Кликает по элементу. Используется только в блоках should или setup. Селектор должен указывать только на один конкретный элемент.
#@param selector [String] селектор элемента
#@param browserName [Symbol] используется, если в разных браузерах нужно кликнуть на разные элементы. Принимает одно из следующих значений: :firefox, :chrome, :ie, :safari
#@return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст сообщения об ошибке, если она возникнет
#@example
#       class SelWeT::Unit
#   
#           ...
#   
#          context "Example" do
#     
#            should "TODO something" do
#              ...
#              Unit.click 'input[type="submit"]'
#           ...
#@see alert_ok
#@see alert_cancel
    def click selector, browserName = nil
      threads = []
      status = true
      @@driver.each do |name, driver|
        if browserName.nil? or name == browserName.to_s
        threads << Thread.new do
          begin
            element = driver.find_element(:css => selector)
            wait = Selenium::WebDriver::Wait.new(:timeout => 15)
            wait.until { driver.find_element(:css => selector).displayed? }
            driver.action.move_to(element).perform
            element.click
          rescue Exception => e
            status = false
          end
        end
      end
      end
      threads.each(&:join)
      if status
        return true
      else
        return [false, "click: Bad selector : #{selector}"]
      end
    end
#Кликает на кнопку 'Ok' в окне алерта. Используется только в блоках should или setup.
#@return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст сообщения об ошибке, если она возникнет
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
      status = true
      error = nil
      threads = []
      @@driver.each_value do |driver|
        threads << Thread.new do
          begin
            driver.switch_to.alert.accept
          rescue
            status = false
            error = 'alert_ok: No alert!'
          end
        end
      end
      threads.each(&:join)
      return status, error
    end
#Кликает на кнопку 'Cancel' в окне алерта. Используется только в блоках should или setup.
#@return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст сообщения об ошибке, если она возникнет
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://inventos.ru/produkty/#top'
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
      status = true
      error = nil
      threads = []
      @@driver.each_value do |driver|
        threads << Thread.new do
          begin
            driver.switch_to.alert.dismiss
          rescue
            puts 'alert_ok: No alert!'
          end
        end
      end
      threads.each(&:join)
      return status, error
    end
#Проверяет наличие элемента. Используется только в блоках should или setup. Возвращает первым аргументом статус выполнения операции (Boolean), вторым - сообщение об ошибке, если она возникнет (String), третьим - текст, содержащийся в элементе (Hash). Третий аргумент имеет следующую структуру: !{"имя_браузера_1" =>["текст"], "имя_браузера_2" =>["текст"],...}. Если по данному селектору найдено более одного элемента, то количество элементов в массиве будет соответствовать их числу, то есть !{"имя_браузера_1" =>["текст_элемента_1", "текст_элемента_2", ...],...}. При установке параметра link
# @param selector [String] css селектор элемента.
# @param link [Boolean] параметр, позволяющий получить значение поля href. Работает только для ссылок.
#@return [[Boolean, String, Hash]]
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://inventos.ru/produkty/#top'
#   
#          context "Example" do
#     
#            should "TODO something" do
#              status, error, data = Unit.checkElement 'a.menu'
#              status, error, data = Unit.checkElement 'a.toolbar', true
#          ...   
#@see checkElements
    def check_element selector, link = nil
      result = [true, "", []]
      threads = []
      data = {}
      @@driver.each do |name, driver|
        threads << Thread.new do
          begin
            wait = Selenium::WebDriver::Wait.new(:timeout => 15)
            wait.until { driver.find_element(:css => selector) }
            elements = driver.find_elements(:css => selector)
          rescue
            Thread.current["issue"] = name
          end 
          if elements.nil? or elements.size == 0
            Thread.current["no_elems"] = name
          else
            elements.each do |element|
              unless link
                if element.attribute('type') == 'submit' or element.attribute('type') == 'button' or element.attribute('type') == 'reset'
                  data[name].nil? ? data[name] = [element.attribute('value')] : data[name] << element.attribute('value')
                else
                  if element.tag_name == 'select'
                    opts = element.text.split("\n")
                    opts.each do |opt|
                      opt.strip!
                    end
                    opts.delete ''
                    data[name].nil? ? data[name] = [opts] : data[name] << opts
                  else
                    data[name].nil? ? data[name] = [element.text] : data[name] << element.text
                  end
                end
              else
                data[name].nil? ? data[name] = [{"link"=>element.attribute('href'), "text"=>element.text}] : data[name] << {"link"=>element.attribute('href'), "text"=>element.text}
              end
            end
          end
        end
      end
      threads.each(&:join)
      threads.each do |i|
        unless i["issue"].nil?
          result[1] = (result[1].empty? ? "Bad selector '#{selector}'! Browsers: "+i["issue"].to_s : result[1]+" "+i["issue"].to_s)
        else
          unless i["no_elems"].nil?
            result[1] = (result[1].empty? ? "Element '#{selector}' is missing. Browsers: "+i["no_elems"].to_s : result[1]+" "+i["no_elems"].to_s)
          end
        end
      end
      unless result[1].empty?
        result[0] = false
        return result
      end
      result[2] = data
      return result
    end
#Проверяет наличие элементов. Используется только в блоках should или setup. Возвращает первым аргументом статус выполнения операции (Boolean), вторым - сообщение об ошибке, если она возникнет (String), третьим - текст, содержащийся в элементах ([Hash, Hash, ...]). Хеши имеют ту же структуру, что и в {check_element}.
# @param selectors [Array] массив css селекторов элементов.
# @param link [Boolean] параметр, позволяющий получить значение поля href. Работает только для ссылок.
#@return [[Boolean, String, [Hash, Hash,...]]]
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://inventos.ru/produkty/#top'
#   
#          context "Example" do
#     
#            should "TODO something" do
#              status, error, data = Unit.check_elements ['input#email','input#password','a']
#              #Получим количество ссылок
#              a_num = data[2]["firefox"].size
#          ...   
#@see check_element   
    def check_elements selectors, link = nil
      result = [true, "", []]
      return [false, "Argument 'selectors' must be Array!", []] unless selectors.class == Array
      selectors.each do |selector|
        status, message, data = check_element(selector, link)
        unless status
          result[1] = (result[1].empty? ? message+"\n" : result[1]+message+"\n")
        end
        result[2] << data
      end
      unless result[1].empty?
        result[0] = false
      end
      return result
    end
#Обновляет страницу. Используется только в блоках should или setup.
#@example
#       class SelWeT::Unit
#   
#         ...
#          @@somePage = 'http://inventos.ru/produkty/#top'
#   
#          context "Example" do
#     
#            should "TODO something" do
#              Unit.refresh
#          ...      
#@see go_to
    def refresh
      threads = []
      @@driver.each_value do |driver|
        threads << Thread.new do
          driver.navigate.refresh
        end
      end
      threads.each(&:join)
    end
#Возвращает тег по заданному селектору. Используется только в блоках should или setup.
# @param selector [String] css селектор
# @return [[Boolean, String, Hash]] первый аргумент - статус, второй - сообщение об ошибке, если она возникает, третий - хеш вида !{имя браузера => тег}.
# @example
#       class SelWeT::Unit
#   
#         ...
#   
#          context "Example" do
#     
#            should 'TODO something' do
#              Unit.go_to @@somePage
#              ...
#              status, message, tags = Unit.get_tag '#some_id'
#          ...
    def get_tag selector
      threads = []
      tags = {}
      status, message = check_element selector
      return [false, "get_tag: "+message] unless status
      @@driver.each do |name, driver|
        threads << Thread.new do
          tags[name] = driver.find_element(:css => selector).tag_name
        end
      end
      threads.each(&:join)
      return [true, "", tags]
    end
#Заполнить поле или выбирает файл для загрузки. Используется только в блоках should или setup.
# @param selector [String] css селектор
# @param value [String] значение, которое необходимо ввести.
# @param postfix [Boolean] используется, если в разных браузерах необходимо ввести разные значения. К value добавляется '_имя_браузера'.
# @return [[Boolean,String]] - первый аргумент - статус выполнения, второй - сообщение об ошибке, если она произойдёт.
#@example
#       class SelWeT::Unit
#   
#         ...
#   
#          context "Example" do
#     
#            should 'TODO something' do
#              Unit.go_to @@somePage
#              ...
#              status, error = Unit.fill 'input#some_id', 'some text' #заполнить текстовое поле
#              status, error = Unit.fill 'input#[type={"file"}]', 'C:\\path\to\file' #выбрать файл для загрузки
#          ...
#@see go_to
#@see post_form
    def fill selector, value, postfix = nil
      result = [true, ""]
      threads = []
      status, message, data = check_element selector 
      unless status
        return [false, message]
      end
      data.each_value do |i|
        if i.size>1
          return [false, "fill: Element with selector #{selector} not uniq!"]
        end
      end
      @@driver.each do |name, driver|
        threads << Thread.new do
          element = driver.find_element(:css => selector)
          driver.action.move_to(element).perform
          begin
            element.clear if element.attribute('type') != 'file'
          rescue
            #skip this
          end
          driver.find_element(:css => selector).send_keys((postfix.nil? ? value : value+"_"+name))
        end
      end
      threads.each(&:join)
      return result
    end
#Возвращает состояние для radio и checkbox. Используется только в блоках should или setup.
# @param selector [String] css селектор
# @return [[Boolean,String/Hash] первый аргумент - статус выполнения, второй - хеш вида !{имя_браузера=>статус} (если radio или checkbox: 1. checked, то статус принимает значение true; 2. unchecked, то статус принимает значение false), или, если первый аргумент равен false - содержит текст ошибки.
#@example
#       class SelWeT::Unit
#   
#         ...
#   
#          context "Example" do
#     
#            should 'TODO something' do
#              Unit.go_to @@somePage
#              ...
#              status, check = Unit.get_status 'input[type="checkbox"]'
#          ...
    def get_status selector
      threads = []
      status, message, data = check_element selector
      return [false, 'get_status: Element not uniq!'] if data.values[0].size>1
      return [false, "get_status: "+message, tag] unless status
      status = true
      @@driver.each do |name, driver|
        threads << Thread.new do
          element = driver.find_element(:css => selector)
          Thread.current['name'] = name
          if element.attribute('type') == 'checkbox' or element.attribute('type') == 'radio'
            Thread.current['status'] = driver.find_element(:css => selector).selected?.inspect
          else
            Thread.current['status'] = "#{element.attribute('type')} is not a checkbox or radio!"
            status = false
          end
        end
      end
      threads.each(&:join)
      statuses = {}
      threads.each do |i|
        statuses[i['name']] = (i['status'] == "true" ? true : i['status'] == "false" ? false : i['status'])
      end
      return [status, statuses]
    end
#Заполнить и отправить форму.
# @param selector [String] css селектор формы.
# @param fields [Hash] хеш. В качестве ключа передается css селектор элемента (String), в качестве значения: 1) для текстовых полей - строка со значением(String). Если в разных браузерах требуется ввести разные значения, то вначале строки необходимо поставить символ &. Тогда в поле запишется данная строка без символа &, но в конце будет добавлен постфикс "_имя браузера"; 2) для checkbox, radio и кнопок(не submit!) - значение :click; 3) для кнопки отправки формы - :submit. Если не будет указана кнопка для отправки формы, то форма всё равно будет отправлена; 4) для select - массив значений(String), которые необходимо выбрать; 5) для file - путь до файла.
# @return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст ошибки, если она возникнет.
#@example
#       class SelWeT::Unit
#   
#         ...
#   
#         context "Example" do
#     
#           should "Successfull authorization" do
#             status, error = Unit.post_form ".form", {'#email' => 'admin@example.ru', '#password' => 'admin', '.checkbox' => :click, '.submit'=>:submit}
#         ...
#@see click
#@see fill
    def post_form selector, fields = nil
      result = [true, ""]
      fields = {} if fields.nil?
      status, message, data = check_element selector
      unless status
        return [false, message]
      end
      data.each do |key, value|
        if value.size>1
          return [false, "post_form: (#{key}) Found more than one form with selector '#{selector}'"] 
        end
      end
      check_elements = ''
      fields.keys.each do |key|
        status, message, data = check_element key
        unless status
          check_elements = (check_elements.empty? ? message+' : '+key+"\n" : check_elements+message+' : '+key+"\n")
        end
        data.each do |browser, value|
          if value.size>1
            check_elements = (check_elements.empty? ? "post_form:(#{browser}) Element of form not uniq : "+key+"\n" : check_elements+"post_form:(#{browser}) Element of form not uniq : "+key+"\n")
          end
        end
      end
      unless check_elements.empty?
        return [false, check_elements]
      end
      submit_button = nil
      bad_args = {}
      fields.each do |key, value|
        if value.class != String and value.class != Symbol
          bad_args[key] = value
        end
        if value.class == Symbol
          if value != :click and value != :submit
            bad_args[key] = value
          end
        end
      end
      return [false, 'post_form: Bad args was passed: '+bad_args.to_s] unless bad_args.empty?
      fields.each do |key, value|
        if value == :click
          click key
        end
        if value == :submit
          submit_button = key
        end
        if value.class == Array
          status, error = set_select_items(key, value)
          return [false, error] unless status
        end          
      end
      fields.delete_if { |key,value| value == :click or value == :submit or value.class == Array }
      threads = []
      errors = nil
      @@driver.each do |name, driver|
        threads << Thread.new do
          form = driver.find_element(:css => selector)
          fields.each do |key, value|
            tag = form.find_element(:css => key).tag_name
            errors = true if tag == 'select'
            begin
              form.find_element(:css => key).clear
            rescue
              #skip this
            end
            if value[0] == '&'
              send_value = value+'_'+name
              send_value.slice! '&'
              form.find_element(:css => key).send_keys(send_value)
            else
              form.find_element(:css => key).send_keys(value)
            end
          end
          unless errors
            form.submit unless submit_button
          end
        end
      end
      threads.each(&:join)
      return [false, 'post_form: For "select" you must pass array with selected values!'] if errors
      click submit_button unless !submit_button
      return result
    end
#Сверяет переданный url с текущим. Используется только в блоках should или setup.
# @param url [String] url, с которым будет сравинваться текущий url.
# @return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст ошибки, если она возникнет.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'Correct link' do
#              Unit.go_to @@somePage
#              ...
#              status, error = Unit.check_location 'http://www.example.com/other_page'
#          ...
#@see go_to
#@see get_location
    def check_location url
      result = [true, ""]
      threads = []
      @@driver.each do |name, driver|
        threads << Thread.new do
          unless driver.current_url == url
            Thread.current["value"] = name
            Thread.current["real"] = driver.current_url
          end
        end
      end
      threads.each(&:join)
      threads.each do |i|
        unless i["value"].nil?
          result[1] = (result[1].empty? ? "Wrong location '#{i['real']}': "+i["value"].to_s : result[1]+" "+i["value"].to_s)
        end
      end
      unless result[1].empty?
        result[0] = false
      end
      return result
    end
#Возвращает текущий url. Используется только в блоках should или setup.
# @return [Hash] ключ - имя браузера, значение - URL.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'Correct link' do
#              Unit.go_to @@somePage
#              ...
#              location = Unit.get_location
#          ...
#@see check_location
#@see go_to
    def get_location
      result = {}
      threads = []
      @@driver.each do |name, driver|
        threads << Thread.new do
          Thread.current["name"] = name
          Thread.current["url"] = driver.current_url
        end
      end
      threads.each(&:join)
      threads.each do |i|
        result[i['name']] = i['url']
      end
      return result
    end
#Сохраняет скриншот текущего состояния браузеров рядом со скриптом. Имя файла будет иметь следующий вид: browsername_filename.png
# @param filename [String] часть имени выходного файла.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'Make screenshot' do
#              Unit.go_to @@somePage
#              ...
#              Unit.screenshot 'TestScreenshot'
#              ... 
    def screenshot filename
      threads = []
      @@driver.each do |name, driver|
        threads << Thread.new do
          driver.save_screenshot("./"+name+"_"+filename+".png")
        end
      end
      threads.each(&:join)
    end
#Открывает ссылку в новом окне и переключается на него.
#@param selector [String] css селектор ссылки.
# @return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст ошибки, если она возникнет.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'TODO somethin' do
#              Unit.go_to @@somePage
#              ...
#              Unit.in_new_window 'a.someclass'
#              ... 
#@see switchToWindow
#@see close_window
    def in_new_window selector
      threads = []
      not_opened = false
      status, message = check_element selector
      unless status
        return [false, message]
      end
      @@driver.each do |name, driver|
        threads << Thread.new do
          a = driver.find_element :css => selector
          if @@win_num == 0
            @@opened_window[name] = {@@win_num => driver.window_handle}
          end
          driver.action.key_down(:shift).perform
          a.click
          driver.action.key_up(:shift).perform
          old_handle = @@opened_window[name].values
          new_handle = (driver.window_handles - old_handle)[0]
          unless new_handle.nil?
            driver.switch_to.window new_handle
            @@opened_window[name][@@win_num+1] = new_handle
          else
            not_opened = true
          end
        end
      end
      threads.each(&:join)
      return [false, "Window not opened!"] if not_opened
      @@win_num += 1
      return true
    end
#Переключиться на другое окно. Окна нумируются в порядке их открытия. Нумирация начинается с 0.
#@param num [Integer] номер окна.
# @return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст ошибки, если она возникнет.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'TODO something' do
#              Unit.openInNewTab 'a.someclass'
#              ...
#              Unit.switchToWindow 0
#              Unit.close_window 1
#              ... 
#@see in_new_window
#@see close_window
    def switch_to_window num
      threads = []
      status = true
      @@driver.each do |name, driver|
        threads << Thread.new do
          if @@opened_window[name].has_key? num
            driver.switch_to.window @@opened_window[name][num]
          else
            status = false
          end
        end
      end
      threads.each(&:join)
      return status, (status ? "" : "Invalid num: '#{num}'")
    end
#Закрыть окно с номером num. Окна нумируются в порядке их открытия. Нумирация начинается с 0. Если необходимо закрыть текущее окно, то перед закрытием необходимо переключиться на другое окно.
#@param num [Integer] номер окна.
# @return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст ошибки, если она возникнет.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'TODO somethin' do
#              Unit.close_window 2
#              ... 
#@see openInNewTab
#@see switchToWindow
    def close_window num
      threads = []
      status = true
      @@driver.each do |name, driver|
        threads << Thread.new do
          current = driver.window_handle
          if current != @@opened_window[name][num]
            driver.switch_to.window @@opened_window[name][num]
            driver.close
            @@opened_window[name].delete_if do |key, value|
              key == num
            end
            driver.switch_to.window current
          else
            status = false
          end
        end
      end
      threads.each(&:join)
      if status
        return true
      else
        return [false, "You must switch to other window before closing this window"]
      end
    end
#Навести курсор на элемент.
#@param selector [String] css селектор элемента.
#@return [[Boolean,String]] Первый аргумент - статус выполнения, второй - текст ошибки, если она возникнет.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'TODO somethin' do
#              Unit.hoverOverElement "div.menu"
#              Unit.click "a.some_url"
#              ... 
    def hoverOverElement selector
      status, message = check_element selector
      unless status
        return [false, message]
      end
      threads = []
      @@driver.each do |name, driver|
        threads << Thread.new do
          element = driver.find_element(:css => selector)
          driver.action.move_to(element).perform
        end
      end
      threads.each(&:join)
      return true
    end
#Получить заголовок окна.
#@return Hash ключ - имя браузера, аргумент - title.
#@example
#       class SelWeT::Unit
#   
#          set_browsers [:firefox, :chrome]
#          set_selenium_server_url 'http://localhost:4444/wd/hub'
#          @@somePage = 'http://www.example.com'
#   
#          context "Example" do
#     
#            should 'TODO somethin' do
#              ...
#              titles = Unit.window_title
#              ... 
    def window_title
      threads = []
      status = true
      @@driver.each do |name, driver|
        threads << Thread.new do
          Thread.current["name"] = name
          Thread.current["title"] = driver.title
        end
      end
      threads.each(&:join)
      titles = {}
      threads.each do |i|
        titles[i["name"]] = i["title"]
      end
      return titles
    end
    
  end
   
end
end