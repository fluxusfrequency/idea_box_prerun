module Finders

  def find(id)
    raw_idea = find_raw_idea(id)
    Idea.new(raw_idea.to_h)
  end

  def search_for(query="")
    query = query.downcase
    find_raw({'title' => query, 'description' => query, 'tags' => query})
  end

  def find_raw(query_hash)
    begin
      found = []
      query_hash.keys.each do |key|
        query_string = query_hash[key]
        database.transaction do
          result = database['ideas'].select do |idea|
            idea[key].downcase.include?(query_string)
          end  
          found << result
        end
      end
      found.flatten.compact.collect do |raw|
        Idea.new(raw)
      end
    rescue
      []
    end
  end

  def find_all_by_tags(*tags)
    raw_ideas = tags.collect do |tag|
      find_raw_idea_by_tag(tag)
    end
    raw_ideas.compact.flatten.collect do |raw_idea|
      Idea.new(raw_idea)
    end
  end

  def find_resources_for_idea(id)
    find(id).resources
  end

  def all_tags
    all.collect do |idea|
      idea.tags.split(", ")
    end
  end

  def find_all_by_time_created(range_start, range_end)
    find_ideas_between_times(range_start, range_end).values.flatten
  end

  def find_ideas_between_times(start_in, stop_in)
    start_time =  Time.parse(start_in)
    stop_time = Time.parse(stop_in)
    group_all_by_time_created.select do |key, value|
       (start_time..stop_time).cover?(key)
    end
  end

  def find_all_by_group(group)
    group_all_by_group[group]
  end

  def find_raw_idea(id)
    database.transaction do
      begin
        database['ideas'].find do |idea|
          idea['id'] == id
        end
      rescue
        return
      end
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