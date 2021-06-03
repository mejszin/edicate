class Structure
    attr_reader :document, :structure, :data
    
    def initialize(document, rules)
        @document = document
        @rules = rules
        @group_count = rules.length
        # Calculate group data and split into subgroups
        @data = split_duplicates(groups())
    end

    def html
        bool, output = true, []
        @data.each do |group_no, subgroups|
            subgroups.each do |subgroup|
                subgroup.each do |line|
                    clr, fwt = bool ? ["#3273DC", "bold"] : ["#00D1B2", "bold"]
                    style = "color: #{clr}; font-weight: #{fwt}"
                    output << "<b style='#{style}'>#{line.raw}</b><br>"
                end
                bool = !bool
            end
        end
        return output.join
    end

    def debug
        @data.each do |group_no, subgroups|
            subgroups.each do |subgroup|
                subgroup.each { |line| puts "#{group_no}\t#{line.raw}" }
                puts "\n"
            end
        end
    end

    def exists_in_group?(tag, group_no, order = [])
        order << group_no
        @rules[group_no.to_s].each do |value|
            if value.is_number?
                # Recursively call method
                return exists_in_group?(tag, value, order)
            elsif value == tag
                # Break out of recursion when tag matches value
                return true, order
            end
        end
        # Return false if no match is found
        return false, order
    end

    def groups()
        lines_dup, data = @document.lines.dup, {}
        # Remove document tags (UNA, UNH, ...)
        until @rules["0"].include?(lines_dup.first.tag.value)
            lines_dup = lines_dup[1..-1]
        end
        # Iterate through lines; increment group index when needed
        line_no, group_no = 0, 0
        until (line_no >= lines_dup.length) or (group_no >= @group_count)
            line = lines_dup[line_no]
            exists, order = exists_in_group?(line.tag.value, group_no)
            if exists
                if data.key?(group_no)
                    data[group_no] << line
                else
                    data[group_no] = [line]
                end
                line_no += 1
            else
                group_no += 1
            end
        end
        return data
    end

    def segment_in_group?(group, segment)
        tag = segment.tag.value
        group.each { |line| return true if tag == line.tag.value }
        return false
    end

    def split_duplicates(data)
        split_data = {}
        data.each do |group_no, lines|
            group = []
            lines.each do |line|
                is_duplicate = true
                group.each_with_index do |subgroup, subgroup_no|
                    unless segment_in_group?(subgroup, line)
                        is_duplicate = false
                        group[subgroup_no] << line
                    end
                end
                # Add line to a new subgroup if it already exists in another
                group << [line] if is_duplicate
            end
            split_data[group_no] = group
        end
        return split_data
    end
end