# -*- ruby -*-
#
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

require "bundler/setup"
require "jekyll/task/i18n"

Jekyll::Task::I18n.define do |task|
  task.locales = ["ja"]
  task.translator_name = "Droonga Project"
  task.translator_email = "droonga@groonga.org"
  task.files = Rake::FileList["**/*.md"]
  task.files += Rake::FileList["{reference,tutorial}/**/*.html"]
  task.files -= Rake::FileList["README.md"]
  task.files -= Rake::FileList["_*/**/*.md"]
  task.files -= Rake::FileList["news/**/*.md"]
  task.files -= Rake::FileList["vendor/**/*.*"]
  task.files -= Rake::FileList["_po/ja/vendor/**/*.*"]
  task.locales.each do |locale|
    task.files -= Rake::FileList["#{locale}/**/*.md"]
  end
  task.custom_translator = lambda do |original, translated, path|
    notice = <<-NOTICE
{% comment %}
##############################################
  THIS FILE IS AUTOMATICALLY GENERATED FROM
  "#{path.po_file}"
  DO NOT EDIT THIS FILE MANUALLY!
##############################################
{% endcomment %}
    NOTICE
    if /^---+$/ =~ translated
      translated = translated.split(/^---+\n/)
      translated[2] = "\n#{notice}\n#{translated[2]}"
      translated.join("---\n")
    else
      "\n#{notice}\n#{translated}"
    end
  end
end

task :default => "jekyll:i18n:translate"
