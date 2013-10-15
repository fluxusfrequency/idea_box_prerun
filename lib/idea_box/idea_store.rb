require 'yaml/store'

class IdeaStore
  class << self
    def database
      if @env == "test"
        @database ||= YAML::Store.new('db/test')
        return @database
      end

      return @database if @database

      @database ||= YAML::Store.new('db/ideabox')
      @database.transaction do
        @database['ideas'] || []
      end
      @database
    end

    def set_test
      @env = "test"
    end

    def all
      ideas = []
      raw_ideas.each_with_index do |data, i|
        ideas << Idea.new(data.merge("id" => i))
      end
      ideas
    end

    def create(attributes)
      database.transaction do
        database['ideas'] << attributes
      end
    end

    def find(id)
      raw_idea = find_raw_idea(id)
      Idea.new(raw_idea.merge("id" => id))
    end

    def find_all_by_tags(*tags)
      raw_ideas = tags.collect do |tag|
        find_raw_idea_by_tag(tag)
      end
      raw_ideas.compact.flatten.collect do |raw_idea|
        Idea.new(raw_idea)
      end
    end

    def find_all_by_time_created(range_start, range_end)
      # 12:00AM to 12:59AM
      # 1:00AM to 1:59AM
      all.group_by
      range_start..range_end.include?
      Date.parse(date).strftime "%l : %M %p"
    end

    def group_all_by_tags
      all.group_by do |idea|
        idea.tags
      end
    end

    def group_all_by_time_created
      all.group_by do |idea|
        idea.created_at.strftime "%l:%M%p"
      end
    end

    def group_all_by_day_created
      all.group_by do |idea|
        idea.created_at.strftime "%a"
      end
    end

    def update(id, data)
      database.transaction do
        database['ideas'][id] = data
      end
    end

    def delete(position)
      database.transaction do
        database['ideas'].delete_at(position)
      end
    end

    def raw_ideas
      database.transaction do |db|
        database['ideas'] ||= []
      end
    end

    def find_raw_idea(id)
      database.transaction do
        database['ideas'].at(id)
      end
    end

    def find_raw_idea_by_tag(tag)
      result = []
      database.transaction do
        database['ideas'].each do |idea|
          result << idea if idea['tags'].to_s.include?(tag)
        end
      end
      result
    end

  end
end