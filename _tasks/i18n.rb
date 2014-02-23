# Copyright (C) 2013-2014 Droonga Project
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License version 2.1 as published by the Free Software Foundation.
#
# This library is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

require "pathname"
require "yard"
require "gettext/tools"

class I18nTask
  class << self
    def define(&block)
      task = new
      yield(task) if block_given?
      task.define
    end
  end

  include Rake::DSL

  attr_accessor :locales
  attr_accessor :files
  attr_accessor :translator_name
  attr_accessor :translator_email
  def initialize
    @po_dir_path = Pathname.new("_po")
    @base_dir_path = Pathname.new(".")
    @locales = []
    @files = []
    @translator_name = nil
    @translator_email = nil
    @yard_locales = {}
  end

  def define
    namespace :i18n do
      namespace :po do
        namespace :edit do
          define_edit_po_update_task
        end

        define_po_update_task
      end

      define_translate_task
    end
  end

  private
  def define_edit_po_update_task
    @locales.each do |locale|
      namespace locale do
        define_edit_po_locale_update_task(locale)
      end
    end
  end

  def define_edit_po_locale_update_task(locale)
    base_po_dir_path = @po_dir_path + locale
    all_po_file_path = @po_dir_path + "#{locale}.po"

    edit_po_file_paths = []
    @files.each do |target_file|
      base_name = File.basename(target_file, ".*")
      po_dir_path = base_po_dir_path + File.dirname(target_file)
      po_file_path = po_dir_path + "#{base_name}.po"
      edit_po_file_path = po_dir_path + "#{base_name}.edit.po"
      edit_po_file_paths << edit_po_file_path

      directory po_dir_path.to_s
      file edit_po_file_path.to_s => [target_file, po_dir_path.to_s] do
        relative_base_path = @base_dir_path.relative_path_from(po_dir_path)
        generator = YARD::I18n::PotGenerator.new(relative_base_path.to_s)
        yard_file = YARD::CodeObjects::ExtraFileObject.new(target_file)
        generator.parse_files([yard_file])
        pot_file_path = po_dir_path + "#{base_name}.pot"
        pot_file_path.open("w") do |pot_file|
          pot_file.puts(generator.generate)
        end
        unless edit_po_file_path.exist?
          if po_file_path.exist?
            cp(po_file_path.to_s, edit_po_file_path.to_s)
          else
            GetText::Tools::MsgInit.run("--input", pot_file_path.to_s,
                                        "--output", edit_po_file_path.to_s,
                                        "--locale", locale,
                                        *msginit_options)
          end
        end
        GetText::Tools::MsgMerge.run("--update",
                                     "--sort-by-file",
                                     "--no-wrap",
                                     edit_po_file_path.to_s,
                                     pot_file_path.to_s)
        if all_po_file_path.exist?
          GetText::Tools::MsgMerge.run("--output", edit_po_file_path.to_s,
                                       "--sort-by-file",
                                       "--no-fuzzy-matching",
                                       "--no-obsolete-entries",
                                       all_po_file_path.to_s,
                                       edit_po_file_path.to_s)
        end
      end
    end

    desc "Update .edit.po files for [#{locale}] locale"
    task :update => edit_po_file_paths.collect(&:to_s)
  end

  def define_po_update_task
    @locales.each do |locale|
      namespace locale do
        define_po_locale_update_task(locale)
      end
    end

    all_update_tasks = @locales.collect do |locale|
      "i18n:po:#{locale}:update"
    end
    desc "Update .po files for all locales"
    task :update => all_update_tasks
  end

  def define_po_locale_update_task(locale)
    base_po_dir_path = @po_dir_path + locale
    all_po_file_path = @po_dir_path + "#{locale}.po"

    po_file_paths = []
    @files.each do |target_file|
      base_name = File.basename(target_file, ".*")
      po_dir_path = base_po_dir_path + File.dirname(target_file)
      po_file_path = po_dir_path + "#{base_name}.po"
      edit_po_file_path = po_dir_path + "#{base_name}.edit.po"
      po_file_paths << po_file_path

      file po_file_path.to_s => [edit_po_file_path.to_s] do
        GetText::Tools::MsgCat.run("--output", po_file_path.to_s,
                                   "--sort-by-file",
                                   "--no-all-comments",
                                   "--no-report-warning",
                                   "--no-obsolete-entries",
                                   "--remove-header-field=POT-Creation-Date",
                                   "--remove-header-field=PO-Revision-Date",
                                   edit_po_file_path.to_s)
      end
    end

    file all_po_file_path.to_s => po_file_paths.collect(&:to_s) do
      GetText::Tools::MsgCat.run("--output", all_po_file_path.to_s,
                                 "--no-fuzzy",
                                 "--no-all-comments",
                                 "--sort-by-msgid",
                                 "--no-obsolete-entries",
                                 *po_file_paths.collect(&:to_s))
    end

    desc "Update .po files for [#{locale}] locale"
    task :update => all_po_file_path.to_s
  end

  def define_translate_task
    @locales.each do |locale|
      namespace locale do
        define_locale_translate_task(locale)
      end
    end

    all_translate_tasks = @locales.collect do |locale|
      "i18n:#{locale}:translate"
    end
    desc "Translate files for all locales"
    task :translate => all_translate_tasks
  end

  def define_locale_translate_task(locale)
    translated_files = []
    @files.each do |target_file|
      translated_file = Pathname(locale) + target_file
      translated_files << translated_file

      translated_file_dir = translated_file.parent
      directory translated_file_dir.to_s
      dependencies = [
        target_file,
        "i18n:po:#{locale}:update",
        translated_file_dir.to_s,
      ]
      file translated_file.to_s => dependencies do
        File.open(target_file) do |input|
          text = translate(input, locale, target_file)
          File.open(translated_file, "w") do |output|
            output.puts(text)
          end
        end
      end
    end

    desc "Translate files for [#{locale}] locale"
    task :translate => translated_files
  end

  def translate(input, locale, target_file)
    text = YARD::I18n::Text.new(input)
    locale_file = locale_file_path(target_file, locale)
    notice = "{% comment %}\n" +
               "##############################################\n" +
               "  THIS FILE IS AUTOMATICALLY GENERATED FROM\n" +
               "  \"#{locale_file}\"\n" +
               "  DO NOT EDIT THIS FILE MANUALLY!\n" +
               "##############################################\n" +
               "{% endcomment %}"
    translated_text = text.translate(yard_locale(locale))
    if /^---+$/ =~ translated_text
      translated_text = translated_text.split(/^---+\n/)
      translated_text[2] = "\n#{notice}\n\n#{translated_text[2]}"
      translated_text = translated_text.join("---\n")
    else
      translated_text = "\n#{notice}\n\n#{translated_text}"
    end
    translated_text
  end

  def locale_file_path(target_file_path, locale)
    "_po/#{locale}/#{target_file_path.sub(/\.[^\.]+\z/, "\.po")}"
  end

  def yard_locale(locale)
    @yard_locales[locale] ||= create_yard_locale(locale)
  end

  def create_yard_locale(locale)
    yard_locale = YARD::I18n::Locale.new(locale)
    messages = GetText::MO.new
    po_parser = GetText::POParser.new
    po_parser.parse_file(@po_dir_path + "#{locale}.po", messages)
    yard_locale.instance_variable_get("@messages").merge!(messages)
    yard_locale
  end

  def msginit_options
    options = []
    if @translator_name
      options.concat(["--translator-name", @translator_name])
    end
    if @translator_email
      options.concat(["--translator-email", @translator_email])
    end
    options
  end
end
