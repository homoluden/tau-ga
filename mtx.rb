require 'narray'

class Array
  alias to_s_old to_s
  def to_s
    "[ " +
    self.collect {
      |val|
      val.to_s
    }.join("\n") +
    " ]"

  end
  alias inspect_old inspect
  def inspect
    "[ " + self.join("\t") + " ]"
  end
  def inspect_tr
    "[  " +
    self.collect {
      |val|
      val.inspect
    }.join("\n   ") +
    "  ]"
  end
end
def diag_nmtx(block,cnt)
  arr = block.to_a
  res = []
  cnt.times {
    |di|
    arr.collect {
      |item|
      row = []
      (di*block.sizes[0]).times {row << 0.0}
      item.collect { |item2| row << item2 }
      (block.sizes[0] * (cnt - di - 1)).times {row << 0.0}
      res << row
    }
  }
  ret = NMatrix.float(cnt*block.sizes[0],cnt*block.sizes[1])
  ret[]=res
  ret
end
def NMatrix.rows(arr)
  res = NMatrix.float(arr[0].length,arr.length)
  res[]=arr
  res
end
class NMatrix
  def arow(ind)
    return self[0..self.sizes[0]-1,ind].to_a[0]
  end
  def acol(ind)
    return self[ind,0..self.sizes[1]-1].transpose.to_a[0]
  end
  def mrow(ind)
    return self[0..self.sizes[0]-1,ind]
  end
  def mcol(ind)
    return self[ind,0..self.sizes[1]-1]
  end
end