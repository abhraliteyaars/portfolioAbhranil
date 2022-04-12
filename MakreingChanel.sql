/*Seeing the basic Data in Site Metrics*/
select * from "SiteMetrics"
select * from "Spend"
select * from "DateTime"

/*By looking at the data we get an understanding of how to go about the analysis*/
/* From the table we can identify which channels are performing well, how do they perform on each 
breakdown like device and browser*/

/* MC performance -- Visits, Bounces, Pruct purchased, Order Quantity*/
select "SiteMetrics"."Marketing channel",
SUM ("SiteMetrics"."Bounced visits") AS BouncedVisits,
SUM ("SiteMetrics"."Product purchased") AS PurchasedVisits,
SUM ("SiteMetrics"."Order quantity") AS Orders
from "SiteMetrics"
GROUP by "SiteMetrics"."Marketing channel"
ORDER by Orders DESC
/* Tracked Social and Referring Domains have a higher success. We also want to see the per 
visit numbers*/
select "SiteMetrics"."Marketing channel",
COUNT("SiteMetrics"."Visit id") as Visits,
SUM ("SiteMetrics"."Bounced visits") AS BouncedVisits,
SUM ("SiteMetrics"."Product purchased") AS PurchasedVisits,
SUM ("SiteMetrics"."Order quantity") AS Orders
from "SiteMetrics"
GROUP by "SiteMetrics"."Marketing channel"
ORDER by Orders DESC


/* We also want to check what is the ratio of New to Return visitors*/
select count(*)
from
(
	/*this helps getting us visitor_id and their count of visits*/
select VisitCount.V as VisID,count(*) as VisTot
from
(
	/* inner-most query: this gives the net count of visits per visitor*/
select "SiteMetrics"."Visitor ID" as V,
count("SiteMetrics"."Visit Number") over(PARTITION by "SiteMetrics"."Visitor ID") as VC
from "SiteMetrics"
) as VisitCount
where VC>1
	/*this filters only those who have visitcount>3*/
group by VisitCount.V
) as VisitorCount

/* In order for us to put success in terms of a percent value we need to add a Order/Visit column*/

/* High performing channels*/

select "Spend"."Marketing channel",
"Spend"."Visits",
SUM("SiteMetrics"."Order quantity"),
SUM (("Order quantity" / "Spend"."Visits")) as OPV
from  "Spend" left join "SiteMetrics"
on "SiteMetrics"."Marketing channel" = "Spend"."Marketing channel"
where "Spend"."Visits" <> 0
GROUP by "Spend"."Marketing channel"
ORDER by OPV desc
LIMIT 5


/*NBPS has the highest OPV followed by Affiliates and Brand Shopping. However the visit count is low*/
/*Is this low count due to less investment?*/

SELECT "Spend"."Marketing channel", "Spend"."Spend"
from "Spend"
ORDER by "Spend"."Spend" DESC

/* The spend amount is decent for Shopping and Affiliates but can be increased fro NBPS*/

/* Low performing channels*/
select "Spend"."Marketing channel",
"Spend"."Visits",
SUM("SiteMetrics"."Order quantity") as Orders,
SUM (("Order quantity" / "Spend"."Visits")) as OPV
from  "Spend" left join "SiteMetrics"
on "SiteMetrics"."Marketing channel" = "Spend"."Marketing channel"
where "Spend"."Visits" <> 0
GROUP by "Spend"."Marketing channel"
ORDER by OPV asc
LIMIT 5

/*Tracked Social media, Paid Search and Brand Text have low OPVs does this also reflect on Purchased visits?*/
select "Spend"."Marketing channel",
"Spend"."Visits",
SUM("SiteMetrics"."Order quantity") as Orders,
SUM (("Order quantity" / "Spend"."Visits")) as OPV,
SUM (("Product purchased" / "Spend"."Visits")) as PPV
from  "Spend" left join "SiteMetrics"
on "SiteMetrics"."Marketing channel" = "Spend"."Marketing channel"
where "Spend"."Visits" <> 0
GROUP by "Spend"."Marketing channel"
ORDER by OPV,PPV asc

/*Yes, the same channels have pretty low PPV as well. Is this because these channels mostly 
attract visits and not conversions?*/
select "SiteMetrics"."Marketing channel",
count("SiteMetrics"."Visit Number") as RetVisCount
from "SiteMetrics"
where "SiteMetrics"."Visit Number"<>1 
AND
"SiteMetrics"."Marketing channel" IN('Tracked Social Media', 'Paid Search', 'Brand Text')
GROUP by "SiteMetrics"."Marketing channel"

/*Only TSM has return visits recorded against. So these channels are mostly used to attract visitors.*/

/*Given that these channels could be used to attract visitors can we see the effectivity of these
channels with respect to the return visits leading to orders?*/

select * from
(
select "SiteMetrics"."Visitor ID","SiteMetrics"."Visit id", 
	"SiteMetrics"."Marketing channel" as MC,"SiteMetrics"."Visit Number",
sum("SiteMetrics"."Order quantity")
over(partition by "SiteMetrics"."Visitor ID" order by "SiteMetrics"."Visitor ID") as Total_Order,
count("SiteMetrics"."Visit id")
over(partition by "SiteMetrics"."Visitor ID")  as Visits
from "SiteMetrics"
) as Ret_Visits
where Visits >1
AND total_order >0
AND MC IN('Tracked Social Media', 'Paid Search', 'Brand Text')

/* we see only 2 such instances where one of these channels helped in funnelling the users to an eventual conversion*/

/*Since these channels are top of the funnel we will also use bounced visits to measure their effectivity*/
/* We will check if the Bounce Rate of these channels are >average*/

select "SiteMetrics"."Marketing channel",
SUM ("SiteMetrics"."Bounced visits") as BounceVisit,
/*Reutrn Bounce visit sum for channels which are greater than average BR*/
SUM ("SiteMetrics"."Bounced visits")
>
/*Bounced visits per Makreting channel*/
(select AVG(

/*Total Bounced visits*/
(select SUM("SiteMetrics"."Bounced visits")
from "SiteMetrics")

	
/*Count of Makreting channels*/
(select count
(distinct "SiteMetrics"."Marketing channel")
from "SiteMetrics")

)
from "SiteMetrics"
group by "SiteMetrics"."Marketing channel"
LIMIT 1
) as GA
from "SiteMetrics"	
group by "SiteMetrics"."Marketing channel"
ORDER by GA,BounceVisit

/* as we can see all 3 have higher bounce rate than average. This needs to be looked at.*/

/*Can we break down the higher bounce rate by other factors like Device browser etc?*/

/* what browsers do we have?*/
select "SiteMetrics"."Browser" from "SiteMetrics"
GROUP by "SiteMetrics"."Browser"

/* will create some views for future comparison*/
create view v_chrome as
select 
"SiteMetrics"."Marketing channel",
SUM ("SiteMetrics"."Bounced visits") as BounceVisit
from "SiteMetrics"
where "SiteMetrics"."Browser"='Chrome'
GROUP by "SiteMetrics"."Marketing channel"

create view v_edge as
select 
"SiteMetrics"."Marketing channel",
SUM ("SiteMetrics"."Bounced visits") as BounceVisit
from "SiteMetrics"
where "SiteMetrics"."Browser"='Edge'
GROUP by "SiteMetrics"."Marketing channel"

select * from v_edge order by bouncevisit desc
select * from v_chrome order by bouncevisit desc
/*Comparing the two views Tracked Social media tranks lower in BR in chrome than in edge. May need to look at 
chrome rendering?*/

/*quick check on how the bounces vary across different combinations Marketing channel, device and browser*/

select 
"SiteMetrics"."Device","SiteMetrics"."Browser","SiteMetrics"."Marketing channel","SiteMetrics"."Entry page id",
SUM("SiteMetrics"."Order quantity") as Ord,
sum("SiteMetrics"."Bounced visits") as BV
from "SiteMetrics"
GROUP by CUBE("SiteMetrics"."Marketing channel","SiteMetrics"."Device","SiteMetrics"."Browser",
			  "SiteMetrics"."Entry page id" )
ORDER by BV DESC

/*This clearly gives us an idea that Mobile>Desktop, Desktop Chrome>Mobile Chrome, and Mobile,Chrome, Ref Dom
have the highest bounced visits when combined
Also entry page 4 has the highest BV and this is in combination with Mobile Device*/

/*See the timewise running total of the orders by day*/
select A."Date", SUM(A."Order quantity")
OVER(order by A."Date" RANGE BETWEEN unbounded PRECEDING
	and current row) as Running
	from(
/*First joining the tables to get ordrs by timestamp. This will be the datasource for the Running total query*/
select "DateTime"."Visit id", "DateTime"."Date","SiteMetrics"."Order quantity"
from "DateTime" join "SiteMetrics"
ON "DateTime"."Visit id" = "SiteMetrics"."Visit id"
		) as A


/*there is a big running total uptick around June-July where the total shoots up between 300-500*/

/*We also want to rank/bucket the users based on 1. No of visits 2.Orders 3. How frequently they purchased*/

/*Applying the the buckets based on values obtained at the visitor level*/
select RFMV.v,
CASE
WHEN M >40 then '3'
WHEN M<40 AND M>30 then '2'
ELSE '1' END as Monetary,
CASE
WHEN F >2 then '3'
WHEN F=2 then '2'
ELSE '1' END as Frequency,
CASE 
WHEN (current_date-R)>2100 then '1'
WHEN (current_date-R)<2100 AND (current_date-R)>2000 then '2'
ELSE '3' END as Recency
from
(
/*Fetching the value at visitor level*/
select v,
max(F) as R,
max(c) as F,
round(avg(s)) as M
from
	(
		/*This subquery is required as we need to join the Date Time table based on the visit id.
		If this were not the case we could have directly fetched the value at a visitor level*/
	select "SiteMetrics"."Visitor ID" as V, 
	"SiteMetrics"."Visit id" as VI,
	"DateTime"."Date" as D,
	count("SiteMetrics"."Visit id") Over(partition by "SiteMetrics"."Visitor ID") as C,
	sum("SiteMetrics"."Order quantity") Over(partition by "SiteMetrics"."Visitor ID") as S,
	first_value("DateTime"."Date") Over(partition by "SiteMetrics"."Visitor ID" Order by "DateTime"."Date" DESC) as F
	from "SiteMetrics" join "DateTime"
	ON "SiteMetrics"."Visit id"= "DateTime"."Visit id"
	) as RFM
	group by v
	) as RFMV
	order by (M, F, R) DESC