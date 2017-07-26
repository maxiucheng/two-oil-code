local strategy={}
strategy.subscrib={}
local ruchangshijian = 0
local chuchangshijian = 0
local chuchangshijianbrunt = 0
local bruntbuyentryprice = 0
local bruntsellentryprice = 0
local newyorkoilbuyentryprice = 0
local newyorkoilsellentryprice = 0
local countprofittimes = 0
local bruntposition = 0 
local value1 = 0 
local uptrend = false
local downtrend = false
strategy.onStart=function(_self)
	strategy.subscrib={MT.getPara('merp'),MT.getPara('merp1')}
end
function GetPreciseDecimal(nNum, n)
    if type(nNum) ~= "number" then
        return nNum;
    end
    
    n = n or 0;
    n = math.floor(n)
    local fmt = '%.' .. n .. 'f'
    local nRet = tonumber(string.format(fmt, nNum))

    return nRet;
end
strategy.onUpdate=function(_self)
    local weekday = os.date("%w",os.time()) 
    local str2 = os.date('%H:%M:%S')
	local h11,m1,s1 = string.match(str2,"(%d+):(%d+):(%d+)")  
	local merpcode =  MT.getPara('merp')
    local merpcode1 =  MT.getPara('merp1')
    local profittarget = MT.getPara('profittarget')
	local price1=MT.getLastPrice(merpcode1 ) --brunt oil price
	local price=MT.getLastPrice(merpcode) --newyork oil price
	local ps=MT.tradePositions(merpcode) --newyork oil
	local ps1=MT.tradePositions(merpcode1) --brunt oil 
    local curtime = os.time()  
    local orders = MT.tradeOrders(merpcode) 
    local orders1 = MT.tradeOrders(merpcode1)
    local bruntbuy1volume =  MT.getBuy1Volumn(merpcode1)
	local bruntsell1volume =  MT.getSell1Volumn(merpcode1)
	local newyorkoilbuy1volume = MT.getBuy1Volumn(merpcode)
    local newyorkoilsell1volume = MT.getSell1Volumn(merpcode)
	local pricedifference1 = MT.getPara('pricedifference1')
	local pricedifference2 = MT.getPara('pricedifference2')
	local count = MT.getPara('count') 
	local paceadding = MT.getPara('paceadding') 
	local fb1 = {} --brunt oil price 
	--local count = math.min((bruntbuy1volume + bruntsell1volume) / 4,(newyorkoilbuy1volume + newyorkoilsell1volume) / 4 )  	
	local test = price1 - price
	local test1 = GetPreciseDecimal(test, 2)
	if curtime -  value1  > 5 then
       print (test1,pricedifference1,pricedifference2)
       value1 = curtime	
   end	 
	if (orders and orders[1]) or (orders1 and orders1[1]) then	     
	   print('检测到有挂单,暂时不进行逻辑判断')
	   return
   end
    if h11 * 3600 + m1 * 60 + s1 > 3 * 3600 + 57 * 60 and  h11 * 3600 + m1 * 60 + s1 < 8 * 3600 + 57 * 60  then
	   return
	end
    if  (ps1 and ps1[1]) and (ps and ps[1])	then --布油有持仓exit standard
        for _,p in ipairs(ps1) do --遍历布油的持仓
            if p.num > 0 then
                bruntbuyentryprice = p.price
            else
                bruntbuyentryprice = 0 
            end
             if p.num < 0 then
                bruntsellentryprice = p.price
            else
                bruntsellentryprice = 0 
            end
            if p.num > 0  and price1 - bruntbuyentryprice + newyorkoilsellentryprice - price - profittarget > -0.001   and curtime - chuchangshijianbrunt -10 > 0 and newyorkoilsellentryprice ~= 0 and not (orders and  orders[1]) and not (orders1 and  orders1[1]) then --假设有布油多单，说明之前的进场是价差缩小时的进场，出场条件应该是价差达到较大值而且有浮盈时候 
		        MT.tradeClosedPosition(p.id)                 
                chuchangshijianbrunt = curtime 
       			bruntposition = 0
       			print('平布油多单') 	
		    end
		    if p.num < 0 and  bruntsellentryprice - price1 + price - newyorkoilbuyentryprice-profittarget>-0.001   and curtime - chuchangshijianbrunt -10 > 0 and newyorkoilbuyentryprice ~= 0 and not (orders and  orders[1]) and not (orders1 and  orders1[1]) then--布油空单在手               
                MT.tradeClosedPosition(p.id) 
                chuchangshijianbrunt = curtime
				bruntposition = 0
                print('平布油空单')   
		    end		   
		    --[[if 7 == weekday + 1 and 4 == h11 + 1 and 58 == m1 + 1 then 
			    MT.tradeClosedPosition(p.id) 
		        chuchangshijian = curtime
                print('周六早上3:57平仓布油')   
			end	]]	
		end     
	 	
		for _,v in ipairs(ps) do --遍历美油的持仓
            if v.num > 0 then
                newyorkoilbuyentryprice = v.price
            else
                newyorkoilbuyentryprice = 0 
            end
             if v.num < 0 then
                newyorkoilsellentryprice = v.price
            else
                newyorkoilsellentryprice = 0 
            end            
            if v.num < 0  and price1 - bruntbuyentryprice + newyorkoilsellentryprice - price -profittarget> -0.001  and curtime - chuchangshijian -10 > 0  and bruntbuyentryprice ~= 0 and not (orders and  orders[1]) and not (orders1 and  orders1[1]) then --假设有美油空单，说明之前的进场是价差缩小时的进场，出场条件应该是价差达到较大值而且有浮盈时候 
		        MT.tradeClosedPosition(v.id)                 			
                chuchangshijian = curtime
                print('平美油空单')      
		    end
		    if v.num > 0 and  bruntsellentryprice - price1 + price - newyorkoilbuyentryprice -profittarget>-0.001  and curtime - chuchangshijian -10 > 0  and bruntsellentryprice ~= 0 and not (orders and  orders[1]) and not (orders1 and  orders1[1]) then-- 美油多单在手， 
		        MT.tradeClosedPosition(v.id) 
		        chuchangshijian = curtime
                print('平美油多单')   
		    end		     
            --[[if 7 == weekday + 1 and 4 == h11 + 1 and 58 == m1 + 1 then 
			    MT.tradeClosedPosition(v.id) 
		        chuchangshijian = curtime
                print('周六早上3:57平仓美油')   
			end	]]
		
		end 	
	end	
	if not (ps1 and ps1[1]) and not (orders and  orders[1])  then
	    for _,v in ipairs(ps) do --遍历美油的持仓
	        if v.num ~= 0 then
			    MT.tradeClosedPosition(v.id) 
		        chuchangshijian = curtime
                print('布油无持仓导致美油平仓2')      
	        end
		end	
	end
    if not (ps and ps[1])  and not (ps1 and ps1[1]) then  
        if price1 - price -pricedifference1 >= -0.001 and curtime - ruchangshijian -30 > 0 and weekday + 1 ~= 7   and not (orders and  orders[1]) and not (orders1 and  orders1[1]) then
            MT.tradePendingOrderSell(merpcode1, count, price1 - paceadding)	--sell brunt
            MT.tradePendingOrderBuy(merpcode, count, price + paceadding)	--buy NY oil
            ruchangshijian = curtime
            bruntsellentryprice = price1
            newyorkoilsellentryprice = price
            bruntposition = 1			
            print('做空布油，做多美油进场')    
        end
		 
        if price1 - price -pricedifference2 <= 0.001 and curtime - ruchangshijian - 30 > 0 and weekday + 1 ~= 7   and not (orders and  orders[1]) and not (orders1 and  orders1[1]) then
            MT.tradePendingOrderBuy(merpcode1, count, price1 + paceadding)--buy brunt
            MT.tradePendingOrderSell(merpcode, count, price - paceadding)--sell NY oil
            ruchangshijian = curtime
            bruntbuyentryprice = price1 
            newyorkoilsellentryprice = price			
            bruntposition = 1
			print('做多布油，做空美油进场')    
        end
         
	end     

--if price1 - price -pricedifference1 > -0.001 then print('day11111111111111111111111111111111111u') end
--if price1 - price - pricedifference2 < 0.001 then print('xiao22222222222222222222222222222222222yu') end
 end 
strategy.paras={count = {'1','手数设置'},paceadding = {'0.01','进场追价设置'},pricedifference1={'2.56','大价差'},pricedifference2={'2.38','小价差'},profittarget={'0.07','利润点数'},merp={'clu7','选择美原油主力合约'},merp1={'coilu7','选择布伦特原油主力合约'}}
--注册策略
MT.registerStrategy(strategy) 