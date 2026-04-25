-- hard-coded dns entries; useful when you can't reach the dns server, but still want a nice name
-- instead of a raw uuid address.
return {
  -- main world hosts (without any suffix!)
  ['dns'] = '81eefbb9-1791-4c01-8948-4dd98fd4cfda',
  -- alex65536's testing hosts (with suffix `.a.test`)
  ['c1.a.test'] = '48e58059-0895-477d-a804-8b3da847c32d',
  ['dns.a.test'] = '9a9ae872-15f8-44d8-a0e1-594678e13766',
  -- wind-eagle's testing hosts (with suffix `.b.test`)
  ['dns.b.test'] = '3fe8adeb-077e-4f64-863a-f4d88a2330e3',
}
