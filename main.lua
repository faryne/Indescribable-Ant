-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------
--[[
注意：任何項目沒加local時即代表是全域變數
]]--
k_index     = 0;
total_pages = 0;
-- Your code here
page        = 1;
per_width   = 120;  -- 每個圖片元件的寬度
per_height  = 120;  -- 每個圖片元件的高度
-- 每列可以擺多少個圖片元件 以display.pixelWidth / per_width得出
per_row     = math.floor(display.contentWidth / per_width);
-- 決定總共可以顯示多少列
row_counts  = 20
-- 每列資料的X軸位置
x_begin_pos = 60
-- 預設的Y軸位置
y_begin_pos = 0;
-- position collections 
pos_tables  = {};

x_begin     = x_begin_pos;
y_begin     = y_begin_pos;

local screen_groups = display.newGroup();


-------------------------------------------------------

--[[
供描繪結果使用，決定是否斷行的依據
]]--
local function is_create_break (idx)
  if (idx % per_row == 0) then
    return true;  
  end

  return false;
end

local function networkListener_v2 (event)
  if ( event.isError ) then
    print ( "Network error - download failed" )
  else    
    -- X軸數字增加
    x_begin = x_begin + per_width
    -- 判斷是否要作換行
    if (is_create_break(k_index) == true) then
      y_begin = per_height + y_begin
      x_begin = x_begin_pos
    end      
    k_index = k_index + 1;
      
    -- 檢查檔案是否存在
    local path = system.pathForFile(event.response.filename, system.TemporaryDirectory)
    local fhd = io.open(path)
    -- 檔案存在時才鋪到頁面
    if fhd then
      -- 確定要從pos_tables的哪個元素取出資料
      pos_data      = nil;
      for k,v in pairs(pos_tables) do
        local f_name = v["site"] .. v["author_id"] .. v["id"] .. ".png";
        if (f_name == event.response.filename) then
          pos_data  = v;
        end
      end
      -- 在畫布上增加圖片元素
      local r_img   = display.newImageRect(event.response.filename, system.TemporaryDirectory, per_width - 5, per_height - 5);
      if (r_img ~= nil and pos_data ~= nil) then
        -- 設定顯示位置
        --r_img:setReferencePoint(display.CenterReferencePoint)
        r_img.x = x_begin;
        r_img.y = y_begin;
        r_img.id  = pos_data["site"] .. pos_data["author_id"] .. pos_data["id"];
        r_img.url = pos_data["page_url"]
        -- 設定圖片元素的監聽器
        function r_img:tap( event )
          print(event.target.url);
          system.openURL(event.target.url);
          return true
        end

        r_img:addEventListener( "tap", r_img )
        group:insert(r_img);
        -- scrollView:insert(r_img);
        -- 移除暫存檔案
        os.remove(system.pathForFile(event.response.filename, system.TemporaryDirectory));
      end
    end
    
  end
end

-- 第二版的描繪結果
local function get_maid_v2 (e)
  if (e.isError) then
    native.showAlert("failed")
    print "failed";
    return false;
  else
    local json    = require "json";
    
    -- parse json
    local result  = json.decode(e.response)
    
    -- 算出會有多少總頁數
    total_pages   = math.ceil(result["header"]["num"] / row_counts)
    pos_tables = {}
    
    for key,value in pairs(result.artworks) do
      table.insert(pos_tables, value);
      -- 組出預覽圖檔名
      local prev_filename = value["site"] .. value["author_id"] .. value["id"] .. ".png";

      -- 讀取預覽圖
      network.download(value["thumbnail"], "GET", networkListener_v2, prev_filename, system.TemporaryDirectory);
      
    end
    -- DONE
  end
end

-- 負責出去撈API的方法
local function query_api (params)
  local params_table = {}
  for k,v in pairs(params) do
    table.insert(params_table, k.."="..v);
  end
  group = display.newGroup();
  local url = "http://api.neko.maid.tw/artwork.json?"..table.concat(params_table, '&');
  network.request(url, "GET", get_maid_v2);
  scrollView:insert(group);
end

-----------------------------------------------------------------------------------------

local widget = require( "widget" )
local function scrollListener( event )
    local phase = event.phase
    local direction = event.direction
    
    -- If we have reached one of the scrollViews limits
    if event.limitReached then
        -- 當往下捲時
        if "up" == direction then
          -- 如果沒有下一頁的話，直接回傳TRUE
          if page >= total_pages then
            return true;
          end
          -- 否則繼續載入下一頁
          page = page + 1;
          local closure = query_api
          {
            start   = row_counts * (page - 1),
            perpage = row_counts
          }
          -- 過0.5秒後繼續載入下一頁
          timer.performWithDelay(500, closure);
        end
    end

    return true
end

scrollView = widget.newScrollView
{
  left          = 0,
  top           = 100,
  width         = 480,
  height        = display.contentHeight - 100,
  scrollWidth   = 480,
  scrollHeight  = 10000,
  listener      = scrollListener,
  horizontalScrollDisabled  = false,
  verticalScrollDisabled    = false,
  hideBackground = false,
  backgroundColor = { 255, 255, 255, 255 },
  --maskFile  = "Default@2x.png"
}
scrollView.isHitTestMasked = true
scrollView:toBack()
screen_groups:insert(scrollView)
print(display.contentWidth)

-- 載入預設資料
query_api
{
  start   = row_counts * (page - 1),
  perpage = row_counts
}
