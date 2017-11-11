require! <[fs d3-dsv]>
data = fs.readdir-sync \../csv
  .map ->
    ret = /0*(\d+).csv/.exec(it)
    year = 1911 + +ret.1
    {data: d3-dsv.csv-parse(fs.read-file-sync "../csv/#it" .toString!), year}
  .map (d,i) ->
    last = null
    d.data.forEach ->
      if it["摘要票卡"] =>
        it["摘要"] = it["摘要票卡"]
        delete it["摘要票卡"]
      it["年度"] = d.year
      if last =>
        if !it["受贈單位/執行單位"] => it["受贈單位/執行單位"] = last["受贈單位/執行單位"]
        if !it["摘要"] => it["摘要"] = last["摘要"]
        if !it["項次"] => it["項次"] = last["項次"]
      if it["受贈單位/執行單位"] and typeof(it["受贈單位/執行單位"]) == \string =>
        it["受贈單位/執行單位"] = it["受贈單位/執行單位"].replace(/[【】]/g,'')
        it["受贈單位/執行單位"] = it["受贈單位/執行單位"].split(\\n).filter(->it)
      last := it
    d.data
  .map ->
    it = it.filter -> !/小\s*計\(元\)|^\s*無\s*$/.exec(it["摘要"])
    it.map ->
      for k,v of it => if v and typeof(v) == \string => it[k] = v.trim!
      if it["金額"] => it["金額"] = +it["金額"].replace(/,/g,'')
    it
  .filter -> it.length
data = data.reduce(((a,b) -> a ++ b), [])
data.sort (a,b) -> b["年度"] - a["年度"]
fs.write-file-sync \../all.json, JSON.stringify(data)

csv = []
keys = [k for k of data.0]
csv.push keys.join(\,)
for item in data =>
  csv.push keys.map(-> "\"#{item[it]}\"").join(',')
fs.write-file-sync \../all.csv, csv.join(\\n)
