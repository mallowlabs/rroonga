# Copyright (C) 2011  Kouhei Sutou <kou@clear-code.com>
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

class DatabaseDumperTest < Test::Unit::TestCase
  include GroongaTestUtils

  setup :setup_database, :before => :append

  setup
  def setup_tables
    Groonga::Schema.define do |schema|
      schema.create_table("Tags",
                          :type => :hash,
                          :key_type => :short_text,
                          :default_tokenizer => :delimit) do |table|
        table.text("name")
      end

      schema.create_table("Users",
                          :type => :hash,
                          :key_type => "ShortText") do |table|
        table.text("name")
      end

      schema.create_table("Posts") do |table|
        table.text("title")
        table.reference("author", "Users")
        table.integer("rank")
        table.unsigned_integer("n_goods")
        table.short_text("tag_text")
        table.reference("tags", "Tags", :type => :vector)
        table.boolean("published")
        table.time("created_at")
      end

      schema.change_table("Users") do |table|
        table.index("Posts.author")
      end

      schema.change_table("Tags") do |table|
        table.index("Posts.tag_text")
      end
    end
  end

  private
  def dump(options={})
    Groonga::DatabaseDumper.new(options).dump
  end

  def posts
    context["Posts"]
  end

  def dumped_schema
    <<-EOS
table_create Posts TABLE_NO_KEY
column_create Posts created_at COLUMN_SCALAR Time
column_create Posts n_goods COLUMN_SCALAR UInt32
column_create Posts published COLUMN_SCALAR Bool
column_create Posts rank COLUMN_SCALAR Int32
column_create Posts tag_text COLUMN_SCALAR ShortText
column_create Posts title COLUMN_SCALAR Text

table_create Tags TABLE_HASH_KEY --key_type ShortText --default_tokenizer TokenDelimit
column_create Tags name COLUMN_SCALAR Text

table_create Users TABLE_HASH_KEY --key_type ShortText
column_create Users name COLUMN_SCALAR Text

column_create Posts author COLUMN_SCALAR Users
column_create Posts tags COLUMN_VECTOR Tags

column_create Tags Posts_tag_text COLUMN_INDEX Posts tag_text

column_create Users Posts_author COLUMN_INDEX Posts author
EOS
  end

  class EmptyTest < DatabaseDumperTest
    def test_default
      assert_equal(dumped_schema, dump)
    end
  end

  class HaveDataTest < DatabaseDumperTest
    setup
    def setup_data
      posts.add(:author => "mori",
                :created_at => Time.parse("2010-03-08 16:52 JST"),
                :n_goods => 4,
                :published => true,
                :rank => 10,
                :tag_text => "search mori",
                :tags => ["search", "mori"],
                :title => "Why search engine find?")
    end

    def test_default
      assert_equal(<<-EOS, dump)
#{dumped_schema.chomp}

load --table Posts
[
["_id","author","created_at","n_goods","published","rank","tag_text","tags","title"],
[1,"mori",1268034720.0,4,true,10,"search mori",["search","mori"],"Why search engine find?"]
]

load --table Tags
[
["_key","name"],
["search",""],
["mori",""]
]

load --table Users
[
["_key","name"],
["mori",""]
]
EOS
    end

    def test_limit_tables
      assert_equal(<<-EOS, dump(:tables => ["Posts"]))
#{dumped_schema.chomp}

load --table Posts
[
["_id","author","created_at","n_goods","published","rank","tag_text","tags","title"],
[1,"mori",1268034720.0,4,true,10,"search mori",["search","mori"],"Why search engine find?"]
]
EOS
    end

    def test_limit_tables_with_regexp
      assert_equal(<<-EOS, dump(:tables => [/Posts?/]))
#{dumped_schema.chomp}

load --table Posts
[
["_id","author","created_at","n_goods","published","rank","tag_text","tags","title"],
[1,"mori",1268034720.0,4,true,10,"search mori",["search","mori"],"Why search engine find?"]
]
EOS
    end

    def test_no_schema
      assert_equal(<<-EOS, dump(:dump_schema => false))
load --table Posts
[
["_id","author","created_at","n_goods","published","rank","tag_text","tags","title"],
[1,"mori",1268034720.0,4,true,10,"search mori",["search","mori"],"Why search engine find?"]
]

load --table Tags
[
["_key","name"],
["search",""],
["mori",""]
]

load --table Users
[
["_key","name"],
["mori",""]
]
EOS
    end

    def test_no_tables
      assert_equal(<<-EOS, dump(:dump_tables => false))
#{dumped_schema.chomp}
EOS
    end
  end

  class PluginTest < DatabaseDumperTest
    def test_standard_plugin
      Groonga::Plugin.register("suggest/suggest")
      assert_equal("register suggest/suggest\n" +
                   "\n" +
                   dumped_schema,
                   dump)
    end
  end
end
