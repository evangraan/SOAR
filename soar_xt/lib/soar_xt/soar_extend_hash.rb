class ::Hash
  def self.deep_merge(a, b)
    a.dup.merge(b) do |_,x,y|
      if (x.is_a?(Hash) && y.is_a?(Hash))
        deep_merge(x,y)
      elsif x.is_a?(Array) && (y.is_a?(Array))
        x + y
      else
        y
      end
    end
  end
end
