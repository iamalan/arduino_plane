require 'mapper'
require 'filter'

mask = {}
mask[67] = [0,1,2]
mask[127] = [7,0]
mask[13] = [0] 

data = [127, 0.699999988079071, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 20, 67, 1.340, 1.650, 1.760, 1.0, 1.0, 1.0, 1.0, 1.0, 13, 0.0, 0.0, 1.0, 1.0, 1.0, 0.0, 0.0, 0.0]


f = Filter.new(mask,8)
filtered = f.apply_filter(data)



m1 = ValueMapper.new ValueMapper::BYTE_MIN_VALUE,ValueMapper::BYTE_MAX_VALUE, -1.0, 1.0


map = {}
map[67] = [m1,m1,m1]
map[127] = [m1,m1]
map[13] = [m1]

m = Mapper.new map

p filtered
p m.apply_map filtered
