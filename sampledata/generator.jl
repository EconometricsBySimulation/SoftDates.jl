# A function that replaces a value at a specific place (say the third )
function Base.replace(x::String, sep::String, rep::String, pos::Integer)
  a = split(x, sep)
  if (length(a)<pos+1) return x end
  join([a[1:(pos-1)]..., join(a[pos:(pos+1)], rep), a[(pos+2):end]...], sep)
end

replace("a1 is a2 is a3", " ", ".", 2)
replace("a1 is a2 is a3", "-", ".", 2)
replace("a1 is a2 is a3", "2", ".", 2)
replace("a1 is a2 is a3", "2", ".", 1)

cd("C:/Users/francis.smart.ctr/GitDir/SoftDatesJL/SoftDatesJL")

using Pkg
Pkg.activate(".")
Pkg.add("Distributions")
using Pkg, Dates, DataFrames, Distributions, CSV

# used lipsum.com to grab 2000 year old document (https://www.lipsum.com/)
lipsum = read("sampledata/Lipsum.txt", String)

lip_par = [replace(i, r"\r|\n" => "") for i in split(lipsum, "\n\r") if i!=""]
lip_sen  = [replace(i, r"\r|\n|^ " => "") for i in split(lipsum, ".") if i!=""]
lip_wrd  = [replace(i, r"\r|\n|^ " => "") for i in split(lipsum, r"\n\r|\s+") if i!=""]

# Units from wikipedia (https://en.wikipedia.org/wiki/United_States_customary_units)
units = split(read("sampledata/Units.txt", String), "\r\n")

sampleset = [sample(lip_sen, 200, replace = false)..., units...]

# DataGenerators
# Type1
# Number of dates to generate
n = 250

dtrange = (Date(now()) - Year(5)):Day(1):Date(now())

startdt = firstdayofweek.(rand(dtrange, n)) + Day.(rand([-2,-1,0,0,0,0,1], n))
enddt  = startdt .+ Day.(rand([4,5,6,6,7,7,7,7,7,8], n))

# Number of days covered from the start to the end
span = Dates.value.(enddt-startdt)

# The reporting rate by date -> I set at .9
coverage = [rand(Binomial(span[i], .9),1)[1] for i in 1:n]

daydates = [sort(sample(startdt[i]:Day(1):enddt[i], coverage[i], replace = false)) for i in 1:n]

notes =  [join(sample(lip_sen, rand(Binomial(3, .25),1)[1]), " ") for i in 1:n]

txtfield = [[join(sample(sampleset, rand([1,2,2,3,4,5,6])),
             sample([". ", "; ", " ", " - ", ", ", ".\n\r", "\n\r", "\n\r\n\r"], 1)[1])
             for j in 1:length(daydates[i])]  for i in 1:n]

sep = sample(split(raw"./- ","") , n)

# txtblocks = [join((notes[i], , ), )]

# We have start dates and end dates and where things get tricky is that we
# have individual records that start at Start and end at End. They are listed
# at the beginning of lines.

# Some lines start with a note before the first date is entered.
# Not every date is covered

# Information to be spread accross the dates
V0 = collect(1:n)
V1 = [join(sample(lip_wrd, rand(Binomial(9, .25),1)[1]), " ") for i in 1:n]
V2 = [sample(lip_sen, 1)[1] for i in 1:n]
V3 = [sample(1:(n*5), 1)[1] for i in 1:n]

# Generate the text fields
[ begin
   x = [join([Dates.format.(daydates[i][j],"dd$(sep[i])mm$(sep[i])yyyy"), txtfield[i][j]]," ") for j in 1:length(daydates[i])]
   replace(join([notes[i], x...], "\n\r"), r"^\n\r" => "")
   end
   for i = 1 : n ]

# Generate date type 1
fmlist = [
  ["dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["E dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["E dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["e dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["e dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["e mm$(sep[i])yyyy" for i in 1:n] ,
  ["e mm$(sep[i])yy"   for i in 1:n] ,
  ["yy$(sep[i])mm$(sep[i])dd"   for i in 1:n] ,
  ["mm$(sep[i])dd$(sep[i])yyyy" for i in 1:n] ,
  ["mm$(sep[i])dd$(sep[i])yy"   for i in 1:n] ,
  ["U dd, yyyy" for i in 1:n] ,
  ["U dd, yy"   for i in 1:n] ,
  ["u dd, yyyy" for i in 1:n] ,
  ["u dd, yy"   for i in 1:n] ]

txtblocks =
    [begin
     [ begin
     x = [join([Dates.format.(daydates[i][j], fmlist[ii][i]), txtfield[i][j]]," ")
       for j = 1:length(daydates[i])]
     replace(join([notes[i], x...], "\n\r"), r"^\n\r" => "")
     end
     for i = 1 : n ]
    end
    for ii = 1:length(fmlist)]

dt = DataFrame(
  type = 1,
  Start = startdt ,
  End = enddt,
  Dates = daydates,
  Text = txtblocks[1],
  V0=V0, V1=V1, V2=V2, V3=V3)

for i in 2:length(fmlist)
    append!(dt,
     DataFrame(type = i,
      Start = startdt ,
      End = enddt,
      Dates = daydates,
      Text = txtblocks[i],
      V0=V0, V1=V1, V2=V2, V3=V3))
    end

CSV.write("sampledata/SampleDates.csv", dt)

########################################################################

# Save starting text
dt[:Text0] = dt[:Text]

# Input Errors

    sloppy_rt = .10

    sloppy_entries = sample(1:n, Int(round(n*sloppy_rt)), replace = false) |> sort

    dt[:sloppy] = [dt[i, :V0] ∈ sloppy_entries for i in 1:size(dt)[1]]

    symbolset = split(raw"./- ","")

    txsloppy = dtrange[dt[:sloppy], :Text]

    # Replace some symbols in the sloppy dates with alternative symbols
    for i in 1:size(txsloppy)[1]
      position = sample(1:2,1)[1]
      for j in 1:length(symbolset)
        txsloppy[i] = replace(txsloppy[i],
          string(symbolset[j % length(symbolset) + 1]),
          string(symbolset[j]),
          position)
      end
    end

    dt[dt[:sloppy], :Text] = txsloppy

# There are also some entries which have the wrong date - 15-19 -> +- 1
    error_rt = .10

    error_entries = sample(1:n, Int(round(n*error_rt)), replace = false) |> sort

    dt[:error] = [dt[i, :V0] ∈ error_entries for i in 1:size(dt)[1]]

    txerror = dt[dt[:error], :Text]

    txerror = [replace(txerror[i], r"1[6-8]\b" => (x -> "$(parse(Int, x)-1)")) for i in 1:size(txerror)[1]]

    # 10% of years are off
    dt[dt[:error], :Text] = txerror

# Drop zeros for some portion of dates
    drop0_rt = .10

    drop0_entries = sample(1:n, Int(round(n*drop0_rt)), replace = false) |> sort

    dt[:drop0] = [dt[i, :V0] ∈ drop0_entries for i in 1:size(dt)[1]]

    txdrop0 = dt[dt[:drop0], :Text]

    txdrop0 = [replace(txdrop0[i], "0"=>"",count = sample([1,1,1,1,2,3],1)[1]) for i in 1:size(txdrop0)[1]]

    dt[dt[:drop0], :Text] = txdrop0

# Rand Δ of numbers are replaced with other random numbers 10 -> 30
    rand_rt = .10

    rand_entries = sample(1:n, Int(round(n*rand_rt)), replace = false) |> sort

    dt[:rand] = [dt[i, :V0] ∈ rand_entries for i in 1:size(dt)[1]]

    txrand = dt[dt[:rand], :Text]

    txrand = [replace(txrand[i], string(sample(0:9,1)[1]), string(sample(0:9,1)[1]), 1) for i in 1:size(txrand)[1]]

    dt[dt[:rand], :Text] = txrand

# Non-standard abbreviation of days of the week: Mon->M or Mo, Tuesday -> Tuesda
    abbrev_rt = .30

    abbrev_entries = sample(1:n, Int(round(n*abbrev_rt)), replace = false) |> sort

    dt[:abbrev] = [dt[i, :V0] ∈ abbrev_entries for i in 1:size(dt)[1]]

    txabbrev = dt[dt[:abbrev], :Text]

    daynames = join(dayname.(now() .+ Day.(0:6)), "|")
    dayabbrs = join(dayabbr.(now() .+ Day.(0:6)), "|")

    randcut(x) = x[1:sample(1:length(x)-1)[1]]

    txabbrev = [replace(txabbrev[i], Regex("\\b($daynames|$dayabbrs)\\b") => randcut ) for i in 1:size(txabbrev)[1]]

    dt[dt[:abbrev], :Text] = txabbrev

CSV.write("sampledata/SampleDatesErrors.csv", dt)

########################################################################
dayranges =
  [begin
    y = daydates[i]
    x = sort(sample(1:length(y), minimum([2,length(y)]), replace = false))
    (length(x) == 2) ? ([y[1:(x[1]-1)], [y[x[1]],y[x[2]]], y[(x[2]+1):end]]) : [y, y[1:0], y[1:0]]
   end
   for i in 1:n]

seprange = sample( ["-", "thru", "through", "till", "to"] , n)

# Generate date type 1
fm2list = [
  ["dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["E dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["E dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["e dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["e dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["e mm$(sep[i])yyyy" for i in 1:n] ,
  ["e mm$(sep[i])yy"   for i in 1:n] ,
  ["yyyy$(sep[i])mm$(sep[i])dd" for i in 1:n] ,
  ["yy$(sep[i])mm$(sep[i])dd"   for i in 1:n] ,
  ["mm$(sep[i])dd$(sep[i])yyyy" for i in 1:n] ,
  ["mm$(sep[i])dd$(sep[i])yy"   for i in 1:n] ,
  ["U dd, yyyy" for i in 1:n] ,
  ["U dd, yy"   for i in 1:n] ]

fr1list = [
    ["dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
    ["dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
    ["E dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
    ["E dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
    ["e dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
    ["e dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
    ["e mm$(sep[i])yyyy" for i in 1:n] ,
    ["e mm$(sep[i])yy"   for i in 1:n] ,
    ["yyyy$(sep[i])mm$(sep[i])dd" for i in 1:n] ,
    ["yy$(sep[i])mm$(sep[i])dd"   for i in 1:n] ,
    ["mm$(sep[i])dd$(sep[i])yyyy" for i in 1:n] ,
    ["mm$(sep[i])dd$(sep[i])yy"   for i in 1:n] ,
    ["mm$(sep[i])dd" for i in 1:n] ,
    ["mm$(sep[i])dd" for i in 1:n]]

fr2list = [
  ["dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["E dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["E dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["e dd$(sep[i])mm$(sep[i])yyyy" for i in 1:n] ,
  ["e dd$(sep[i])mm$(sep[i])yy"   for i in 1:n] ,
  ["e mm$(sep[i])yyyy" for i in 1:n] ,
  ["e mm$(sep[i])yy"   for i in 1:n] ,
  ["yyyy$(sep[i])mm$(sep[i])dd" for i in 1:n] ,
  ["yy$(sep[i])mm$(sep[i])dd"   for i in 1:n] ,
  ["mm$(sep[i])dd$(sep[i])yyyy" for i in 1:n] ,
  ["mm$(sep[i])dd$(sep[i])yy"   for i in 1:n] ,
  ["dd$(sep[i])yyyy" for i in 1:n] ,
  ["dd$(sep[i])yyyy" for i in 1:n] ]


dtrange = dt[1:0,]

for k in 1:length(fm2list)

  textblock = [ begin
     dtr = dayranges[i]
      x1 =
        if length(dtr[1]) > 0
        join([join([Dates.format(dtr[1][j],fm2list[k][i]), txtfield[i][j]]," ")
              for j in 1:length(dtr[1])], "\n\r")
        else ""
        end

      x2 = if length(dtr[2]) == 2
        d1 = Dates.format(dtr[2][1], fr1list[k][i])
        sepr = seprange[i]
        d2 = Dates.format(dtr[2][2], fr2list[k][i])
        t1 = txtfield[i][length(dtr[1])+1]
        "$d1 $sepr $d2 $t1"
        else ""
        end

      x3 =
       if length(dtr[3]) > 0
         join([join([Dates.format(dtr[3][j],fm2list[k][i]), txtfield[i][j]]," ")
           for j in 1:length(dtr[3])], "\n\r")
       else ""
       end

      replace(join([x1, x2, x3], "\n\r"), r"^\n\r"=>"")
     end
     for i = 1 : n ]

    df_temp = DataFrame(
        type = k,
        Start = startdt ,
        End = enddt,
        Dates = daydates,
        Text = textblock,
        V0=V0, V1=V1, V2=V2, V3=V3)

    append!(dtrange, df_temp)
end

dtrange
dtrange[:Text]

CSV.write("sampledata/SampleDateRanges.csv", dtrange)

##############################################################################

# Save starting text
dtrange[:Text0] = dtrange[:Text]

# Input Errors

    sloppy_rt = .10

    sloppy_entries = sample(1:n, Int(round(n*sloppy_rt)), replace = false) |> sort

    dtrange[:sloppy] = [dtrange[i, :V0] ∈ sloppy_entries for i in 1:size(dtrange)[1]]

    symbolset = split(raw"./- ","")

    txsloppy = dtrange[dtrange[:sloppy], :Text]


    # Replace some symbols in the sloppy dates with alternative symbols
    for i in 1:size(txsloppy)[1]
      position = sample(1:2,1)[1]
      for j in 1:length(symbolset)
        txsloppy[i] = replace(txsloppy[i],
          string(symbolset[j % length(symbolset) + 1]),
          string(symbolset[j]),
          position)
      end
    end

    dtrange[dtrange[:sloppy], :Text] = txsloppy

# There are also some entries which have the wrong date - 15-19 -> +- 1
    error_rt = .10

    error_entries = sample(1:n, Int(round(n*error_rt)), replace = false) |> sort

    dtrange[:error] = [dtrange[i, :V0] ∈ error_entries for i in 1:size(dtrange)[1]]

    txerror = dtrange[dtrange[:error], :Text]

    txerror = [replace(txerror[i], r"1[6-8]\b" => (x -> "$(parse(Int, x)-1)")) for i in 1:size(txerror)[1]]

    # 10% of years are off
    dtrange[dtrange[:error], :Text] = txerror

# Drop zeros for some portion of dates
    drop0_rt = .10

    drop0_entries = sample(1:n, Int(round(n*drop0_rt)), replace = false) |> sort

    dtrange[:drop0] = [dtrange[i, :V0] ∈ drop0_entries for i in 1:size(dtrange)[1]]

    txdrop0 = dtrange[dtrange[:drop0], :Text]

    txdrop0 = [replace(txdrop0[i], "0"=>"",count = sample([1,1,1,1,2,3],1)[1]) for i in 1:size(txdrop0)[1]]

    dtrange[dtrange[:drop0], :Text] = txdrop0

# Rand Δ of numbers are replaced with other random numbers 10 -> 30
    rand_rt = .10

    rand_entries = sample(1:n, Int(round(n*rand_rt)), replace = false) |> sort

    dtrange[:rand] = [dtrange[i, :V0] ∈ rand_entries for i in 1:size(dtrange)[1]]

    txrand = dtrange[dtrange[:rand], :Text]

    txrand = [replace(txrand[i], string(sample(0:9,1)[1]), string(sample(0:9,1)[1]), 1) for i in 1:size(txrand)[1]]

    dtrange[dtrange[:rand], :Text] = txrand

# Non-standard abbreviation of days of the week: Mon->M or Mo, Tuesday -> Tuesda
    abbrev_rt = .30

    abbrev_entries = sample(1:n, Int(round(n*abbrev_rt)), replace = false) |> sort

    dtrange[:abbrev] = [dtrange[i, :V0] ∈ abbrev_entries for i in 1:size(dtrange)[1]]

    txabbrev = dtrange[dtrange[:abbrev], :Text]

    daynames = join(dayname.(now() .+ Day.(0:6)), "|")
    dayabbrs = join(dayabbr.(now() .+ Day.(0:6)), "|")

    randcut(x) = x[1:sample(1:length(x)-1)[1]]

    txabbrev = [replace(txabbrev[i], Regex("\\b($daynames|$dayabbrs)\\b") => randcut ) for i in 1:size(txabbrev)[1]]

    dtrange[dtrange[:abbrev], :Text] = txabbrev

CSV.write("sampledata/SampleDatesRangeErrors.csv", dtrange)
