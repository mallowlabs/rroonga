# Copyright (C) 2009-2011  Kouhei Sutou <kou@clear-code.com>
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

class ContextTest < Test::Unit::TestCase
  include GroongaTestUtils

  def test_default
    context = Groonga::Context.default
    assert_equal(Groonga::Encoding.default, context.encoding)
  end

  def test_default_options
    Groonga::Context.default_options = {
      :encoding => :utf8,
    }
    context = Groonga::Context.default
    assert_equal(Groonga::Encoding::UTF8, context.encoding)
  end

  def test_create_database
    db_path = @tmp_dir + "db"
    assert_not_predicate(db_path, :exist?)
    context = Groonga::Context.new
    assert_equal(nil, context.database)
    database = context.create_database(db_path.to_s)
    assert_predicate(db_path, :exist?)
    assert_not_predicate(database, :closed?)
    assert_equal(database, context.database)
  end

  def test_create_temporary_database
    before_files = @tmp_dir.children
    context = Groonga::Context.new
    database = context.create_database
    assert_nil(database.name)
    assert_equal(before_files, @tmp_dir.children)
  end

  def test_open_database
    db_path = @tmp_dir + "db"
    database = Groonga::Database.create(:path => db_path.to_s)
    database.close

    assert_predicate(database, :closed?)
    called = false
    context = Groonga::Context.new
    context.open_database(db_path.to_s) do |_database|
      database = _database
      assert_not_predicate(database, :closed?)
      called = true
    end
    assert_true(called)
    assert_predicate(database, :closed?)
  end

  def test_encoding
    context = Groonga::Context.new
    assert_equal(Groonga::Encoding.default, context.encoding)

    context = Groonga::Context.new(:encoding => :utf8)
    assert_equal(Groonga::Encoding::UTF8, context.encoding)
  end

  def test_inspect
    context = Groonga::Context.new(:encoding => Groonga::Encoding::UTF8)
    assert_equal("#<Groonga::Context " +
                 "encoding: <:utf8>, " +
                 "database: <nil>>",
                 context.inspect)
  end

  def test_inspect_with_database
    db = Groonga::Database.create
    context = Groonga::Context.default
    assert_equal("#<Groonga::Context " +
                 "encoding: <#{Groonga::Encoding.default.inspect}>, " +
                 "database: <#{db.inspect}>>",
                 context.inspect)
  end

  def test_array_reference_by_string
    Groonga::Database.create
    context = Groonga::Context.default
    assert_equal("Int32", context["<int>"].name)
  end

  def test_array_reference_by_symbol
    Groonga::Database.create
    context = Groonga::Context.default
    assert_equal("Bool", context[:Bool].name)
  end

  def test_shortcut_access
    Groonga::Database.create
    assert_equal("ShortText", Groonga["ShortText"].name)
  end

  def test_support_zlib?
    assert_boolean(Groonga::Context.default.support_zlib?)
  end

  def test_support_lzo?
    assert_boolean(Groonga::Context.default.support_lzo?)
  end

  def test_match_escalation_threshold
    assert_equal(0, context.match_escalation_threshold)
    context.match_escalation_threshold = -1
    assert_equal(-1, context.match_escalation_threshold)
  end
end
