class Frda::RangeQueryDates
  attr_reader :start_date, :end_date, :range_query
  def initialize(start_d, end_d="", options={})
    @_start = start_d
    @_end = end_d
    @options = options
  end
  
  def range_query
    "#{@options[:field] || 'search_date_dtsim'}:[#{start_date} TO #{end_date}]"
  end
  
  def start_date
    "#{DateTime.parse(simple_start).strftime("%Y-%m-%d")}T00:00:00Z"
  end
  
  def end_date
    "#{(DateTime.parse(simple_end)).strftime("%Y-%m-%d")}T23:59:59Z"
  end
  
  private

  def start_year
    case
      when full_date_search?
        DateTime.parse(@_start).strftime("%Y")
      when year_and_month_search?
        DateTime.parse("#{@_start}-01").strftime("%Y")
      when year_only_search?
        DateTime.parse("#{@_start}-01-01").strftime("%Y")
    end
  end
  
  def end_year
    return start_year if single_date_search?
    case
      when full_end_date?
        DateTime.parse(@_end).strftime("%Y")
      when end_year_and_month_date?
        DateTime.parse("#{@_end}-01").strftime("%Y")
      when end_year_only_date?
        DateTime.parse("#{@_end}-01-01").strftime("%Y")
    end
  end
  
  def start_month
    case
      when full_date_search?
        DateTime.parse(@_start).strftime("%m")
      when year_and_month_search?
        DateTime.parse("#{@_start}-01").strftime("%m")
      when year_only_search?
        DateTime.parse("#{@_start}-01-01").strftime("%m")
      end
  end
  
  def end_month
    case
      when full_end_date?
        DateTime.parse(@_end).strftime("%m")
      when end_year_and_month_date?
        DateTime.parse("#{@_end}-01").strftime("%m")
      when (end_year_only_date? or year_only_search?)
        # this should always be Dec. 31st
        "12"
      else
        start_month
    end
  end
  
  def start_day
    case
      when full_date_search?
        DateTime.parse(@_start).strftime("%d")
      when year_and_month_search?
        DateTime.parse("#{@_start}-01").strftime("%d")
      when year_only_search?
        DateTime.parse("#{@_start}-01-01").strftime("%d")
    end
  end
  
  def end_day
    return (DateTime.parse(simple_start)).strftime("%d") if (single_date_search? and full_date_search?)
    case
      when full_end_date?
        (DateTime.parse(@_end)).strftime("%d")
      when (end_year_and_month_date? or year_only_search? or year_and_month_search?)
        # this ensures we get the last day of the month.
        ((DateTime.parse("#{end_year}-#{end_month}-01") + 1.month) - 1.day).strftime("%d")        
      when end_year_only_date?
        # this should always be Dec. 31st
        "31"
    end
  end
  
  def simple_start
    "#{start_year}-#{start_month}-#{start_day}"
  end
  
  def simple_end
    "#{end_year}-#{end_month}-#{end_day}"
  end
  
  def single_date_search?
    @_start and @_end.blank?
  end

  def year_only_search?
    @_start.strip =~ /^\d{4}$/
  end

  def year_and_month_search?
    @_start.strip =~ /^\d{4}-\d{2}$/
  end  
  
  def full_date_search?
    @_start.strip =~ /^\d{4}-\d{2}-\d{2}$/
  end
  
  
  def end_year_only_date?
    !@_end.blank? and @_end.strip =~ /^\d{4}$/
  end
  
  def end_year_and_month_date?
    !@_end.blank? and @_end.strip =~ /^\d{4}-\d{2}$/
  end
  
  def full_end_date?
    !@_end.blank? and @_end.strip =~ /^\d{4}-\d{2}-\d{2}$/
  end
  
end