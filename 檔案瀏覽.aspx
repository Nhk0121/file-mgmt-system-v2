<%@ Page Language="C#" MasterPageFile="~/主版面.master" AutoEventWireup="true" CodeFile="檔案瀏覽.aspx.cs" Inherits="檔案瀏覽" Title="檔案管理" %>
<asp:Content ID="Content1" ContentPlaceHolderID="主內容" runat="server">
<style>
.fm-wrap{max-width:none;}
.fm-shell{display:grid;grid-template-columns:260px minmax(0,1fr);gap:18px;align-items:start;}
.fm-nav{position:sticky;top:18px;background:#fff;border:1px solid #e9eef5;border-radius:16px;box-shadow:0 12px 28px rgba(15,35,71,.06);overflow:hidden;}
.fm-nav-head{padding:18px 18px 14px;background:linear-gradient(160deg,#f7fbff,#eef4ff);}
.fm-nav-title{font-size:15px;font-weight:700;color:#17325c;margin-bottom:6px;}
.fm-nav-sub{font-size:12px;color:#6b7a90;line-height:1.5;}
.fm-nav-body{padding:14px;}
.fm-quick{display:grid;gap:8px;margin-bottom:14px;}
.fm-qbtn{display:flex;align-items:center;gap:10px;width:100%;padding:10px 12px;border:1px solid #e9eef5;border-radius:12px;background:#fff;color:#1a2a43;cursor:pointer;font-size:13px;font-family:inherit;transition:all .18s;}
.fm-qbtn:hover{border-color:#bdd3ff;background:#f7faff;}
.fm-qbtn.on{border-color:#1677ff;background:#edf4ff;color:#1454b8;box-shadow:inset 0 0 0 1px rgba(22,119,255,.08);}
.fm-qico{width:28px;height:28px;border-radius:9px;display:flex;align-items:center;justify-content:center;background:#edf4ff;color:#1677ff;flex-shrink:0;}
.fm-tree-box{border-top:1px solid #eef2f7;padding-top:12px;}
.fm-tree-title{display:flex;align-items:center;justify-content:space-between;font-size:12px;font-weight:700;color:#718198;margin-bottom:10px;text-transform:uppercase;letter-spacing:.08em;}
.fm-tree{display:grid;gap:3px;max-height:calc(100vh - 280px);overflow:auto;padding-right:4px;}
.tree-node{display:flex;align-items:center;gap:8px;padding:8px 10px;border-radius:10px;color:#30415b;font-size:13px;cursor:pointer;transition:background .15s,color .15s;}
.tree-node:hover{background:#f6f9fc;}
.tree-node.on{background:#edf4ff;color:#1454b8;font-weight:600;}
.tree-node .tri{width:14px;text-align:center;color:#8aa0bd;font-size:10px;cursor:pointer;flex-shrink:0;}
.tree-node .tri.empty{visibility:hidden;}
.tree-node .label{flex:1;min-width:0;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;}
.tree-node .count{font-size:11px;color:#8fa0b6;background:#f3f6fa;border-radius:999px;padding:1px 6px;flex-shrink:0;}
.tree-children{display:none;margin-left:16px;border-left:1px dashed #dbe4ef;padding-left:8px;}
.tree-children.on{display:grid;}
.fm-main{min-width:0;}
/* 頁頭 */
.fm-head{display:flex;align-items:flex-start;justify-content:space-between;margin-bottom:18px;}
.fm-title{font-size:24px;font-weight:700;color:#1a1a2e;}
.fm-sub{font-size:13px;color:#8c8c8c;margin-top:3px;}
.fm-stats{display:flex;gap:16px;font-size:13px;color:#595959;}
.fm-stat{display:flex;align-items:center;gap:5px;}
/* 麵包屑 */
.fm-bc{display:flex;align-items:center;gap:6px;font-size:14px;margin-bottom:14px;flex-wrap:wrap;}
.bc-link{color:#1677ff;cursor:pointer;background:none;border:none;font-size:14px;font-family:inherit;padding:0;}
.bc-link:hover{text-decoration:underline;}
.bc-sep{color:#bfbfbf;font-size:12px;}
.bc-cur{color:#1a1a2e;font-weight:500;}
/* 工具列 */
.fm-toolbar{position:sticky;top:18px;z-index:20;margin-bottom:16px;}
.fm-bar{display:flex;align-items:center;gap:10px;padding:12px;border:1px solid #e8edf5;border-radius:16px;background:rgba(255,255,255,.9);backdrop-filter:blur(12px);box-shadow:0 10px 24px rgba(15,35,71,.05);margin-bottom:10px;}
.fm-search{display:flex;align-items:center;gap:8px;background:#f8fafc;border:1px solid #e8eef5;border-radius:12px;padding:10px 14px;flex:1;max-width:420px;}
.fm-search input{border:none;outline:none;font-size:14px;font-family:inherit;color:#1a1a2e;width:100%;background:transparent;}
.fm-search i{color:#bfbfbf;font-size:14px;}
.fm-chip{display:inline-flex;align-items:center;gap:7px;padding:9px 12px;border:1px solid #e8eef5;border-radius:12px;background:#fff;color:#617086;font-size:12px;font-weight:600;}
.view-group{display:flex;border:1px solid #e8e8e8;border-radius:12px;overflow:hidden;background:#fff;}
.vb{padding:9px 12px;border:none;background:transparent;cursor:pointer;color:#8c8c8c;font-size:14px;transition:all .15s;}
.vb.on{background:#f0f5ff;color:#1677ff;}
.btn-add{display:flex;align-items:center;gap:7px;padding:10px 18px;background:linear-gradient(135deg,#1677ff,#1454b8);color:#fff;border:none;border-radius:12px;font-size:14px;font-weight:600;cursor:pointer;font-family:inherit;transition:transform .15s, box-shadow .15s;}
.btn-add:hover{opacity:1;transform:translateY(-1px);box-shadow:0 10px 20px rgba(22,119,255,.22);}
.btn-add:hover{opacity:.88;}
.fm-summary{display:flex;align-items:center;justify-content:space-between;gap:10px;padding:0 2px 4px;}
.fm-summary-text{font-size:12px;color:#718198;}
.fm-summary-actions{display:flex;align-items:center;gap:8px;}
/* 格狀 */
.fm-grid{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:14px;}
.fm-card{background:linear-gradient(180deg,#fff,#fbfdff);border:1px solid #ebf0f6;border-radius:16px;padding:18px 16px 14px;cursor:pointer;transition:all .18s;position:relative;text-align:left;user-select:none;box-shadow:0 10px 20px rgba(15,35,71,.04);}
.fm-card:hover{border-color:#91caff;box-shadow:0 14px 28px rgba(22,119,255,.12);transform:translateY(-2px);}
.fm-card.sel{border-color:#1677ff;background:#f0f5ff;}
.fm-card .ico{font-size:40px;margin-bottom:12px;display:flex;align-items:center;justify-content:center;width:56px;height:56px;border-radius:16px;background:#f4f8ff;}
.fm-card .ico-folder{color:#1677ff;}
.fm-card .nm{font-size:13px;font-weight:700;color:#1a1a2e;word-break:break-all;line-height:1.45;margin-bottom:4px;min-height:38px;}
.fm-card .info{font-size:11px;color:#8c8c8c;margin-bottom:10px;}
.fm-card .badge-row{display:flex;justify-content:flex-start;gap:4px;flex-wrap:wrap;}
.fm-badge{font-size:10px;padding:2px 8px;border-radius:20px;font-weight:500;}
.b-sys{background:#f5f5f5;color:#595959;}
.b-perm{background:#e6f0ff;color:#1677ff;}
.b-temp{background:#fff7e6;color:#d46b08;}
.b-wait{background:#fffbe6;color:#d46b08;}
.b-ok{background:#f6ffed;color:#389e0d;}
.b-red{background:#fff1f0;color:#cf1322;}
/* 清單 */
.fm-list-head{display:grid;grid-template-columns:1fr 110px 88px 130px 120px 60px;align-items:center;padding:10px 16px;font-size:11px;font-weight:600;color:#8c8c8c;border-bottom:1px solid #f0f0f0;background:#fafafa;border-radius:14px 14px 0 0;}
.fm-list-row{display:grid;grid-template-columns:1fr 110px 88px 130px 120px 60px;align-items:center;padding:12px 16px;font-size:13px;border-bottom:1px solid #f0f0f0;cursor:pointer;transition:background .15s;gap:4px;}
.fm-list-row:last-child{border-bottom:none;}
.fm-list-row:hover{background:#fafafa;}
.fm-list-row.sel{background:#f0f5ff;}
.fn-cell{display:flex;align-items:center;gap:10px;}
.fn-ico{font-size:22px;flex-shrink:0;}
.fn-name{font-weight:500;color:#1a1a2e;word-break:break-all;}
.fn-sub{font-size:11px;color:#8c8c8c;margin-top:1px;}
/* 右鍵選單 */
.ctx-menu{display:none;position:fixed;background:#fff;border:1px solid #f0f0f0;border-radius:8px;box-shadow:0 4px 20px rgba(0,0,0,.15);min-width:160px;z-index:9000;padding:4px 0;}
.ctx-menu.on{display:block;}
.ctx-item{display:flex;align-items:center;gap:9px;padding:8px 14px;font-size:13px;color:#1a1a2e;cursor:pointer;transition:background .1s;}
.ctx-item:hover{background:#f5f5f5;}
.ctx-item.red{color:#cf1322;}
.ctx-sep{height:1px;background:#f0f0f0;margin:3px 0;}
/* 上傳進度 */
.up-toast{display:none;position:fixed;bottom:20px;right:20px;background:#fff;border-radius:10px;box-shadow:0 4px 20px rgba(0,0,0,.15);width:300px;z-index:8000;border:1px solid #f0f0f0;overflow:hidden;}
.up-toast.on{display:block;}
.ut-head{background:#1a1a2e;color:#fff;padding:10px 14px;font-size:13px;font-weight:600;display:flex;justify-content:space-between;align-items:center;}
.ut-item{padding:9px 14px;border-bottom:1px solid #f0f0f0;font-size:12px;}
.ut-bar{height:3px;background:#f0f0f0;margin-top:5px;border-radius:2px;}
.ut-fill{height:100%;background:#1677ff;border-radius:2px;transition:width .3s;}
/* 新增對話框 */
.modal-wrap{display:none;position:fixed;inset:0;background:rgba(0,0,0,.45);z-index:9500;align-items:center;justify-content:center;}
.modal-wrap.on{display:flex;}
.modal-box{background:#fff;border-radius:12px;padding:24px;width:380px;box-shadow:0 8px 32px rgba(0,0,0,.2);}
.modal-title{font-size:16px;font-weight:700;margin-bottom:16px;color:#1a1a2e;}
.modal-inp{width:100%;padding:9px 12px;border:1px solid #d9d9d9;border-radius:8px;font-size:14px;font-family:inherit;color:#1a1a2e;margin-bottom:14px;}
.modal-inp:focus{outline:none;border-color:#1677ff;}
.modal-btns{display:flex;justify-content:flex-end;gap:8px;}
.mbtn{padding:7px 18px;border-radius:6px;font-size:13px;font-weight:600;font-family:inherit;cursor:pointer;border:1px solid #d9d9d9;background:#fff;color:#1a1a2e;}
.mbtn.primary{background:#1677ff;color:#fff;border-color:#1677ff;}
/* 預覽 */
.prev-wrap{display:none;position:fixed;inset:0;background:rgba(0,0,0,.6);z-index:9999;padding:40px;}
.prev-box{background:#fff;border-radius:12px;height:100%;display:flex;flex-direction:column;}
.prev-head{padding:12px 18px;border-bottom:1px solid #f0f0f0;display:flex;justify-content:space-between;align-items:center;}
/* 空狀態 */
.empty-box{text-align:center;padding:60px 20px;color:#8c8c8c;}
.empty-box .ei{font-size:56px;opacity:.2;display:block;margin-bottom:14px;}
/* 拖放 */
.drop-over .fm-grid, .drop-over .fm-list-head{outline:3px dashed #1677ff;outline-offset:4px;border-radius:8px;}
.fm-hidden{display:none!important;}
@media (max-width: 1100px){
  .fm-shell{grid-template-columns:1fr;}
  .fm-nav{position:relative;top:auto;}
  .fm-tree{max-height:260px;}
}
@media (max-width: 760px){
  .fm-head,.fm-bar,.fm-summary{flex-direction:column;align-items:stretch;}
  .fm-stats,.fm-summary-actions{flex-wrap:wrap;}
  .fm-search{max-width:none;}
  .fm-grid{grid-template-columns:1fr 1fr;}
  .fm-list-head,.fm-list-row{grid-template-columns:1fr 84px 72px 96px;}
  .fm-list-head div:nth-child(4),.fm-list-head div:nth-child(5),.fm-list-head div:nth-child(6),
  .fm-list-row > div:nth-child(4),.fm-list-row > div:nth-child(5),.fm-list-row > div:nth-child(6){display:none;}
}
@media (max-width: 520px){
  .fm-grid{grid-template-columns:1fr;}
}
</style>

<!-- 頁頭 -->
<div class="fm-wrap">
<div class="fm-shell">
<aside class="fm-nav">
  <div class="fm-nav-head">
    <div class="fm-nav-title">資料夾導覽</div>
    <div class="fm-nav-sub">像檔案總管一樣先選資料夾，再在右側管理內容。</div>
  </div>
  <div class="fm-nav-body">
    <div class="fm-quick">
      <button type="button" class="fm-qbtn" id="quickRoot" onclick="navTo('')">
        <span class="fm-qico"><i class="fas fa-home"></i></span>
        <span>目前儲存區根目錄</span>
      </button>
      <button type="button" class="fm-qbtn" id="quickZone" onclick="navTo('')">
        <span class="fm-qico"><i class="fas fa-database"></i></span>
        <span id="quickZoneLabel">目前儲存區</span>
      </button>
    </div>
    <div class="fm-tree-box">
      <div class="fm-tree-title">
        <span>資料夾樹</span>
        <button type="button" onclick="reloadTree()" style="background:none;border:none;color:#8aa0bd;cursor:pointer;font-size:12px;">
          <i class="fas fa-rotate-right"></i>
        </button>
      </div>
      <div class="fm-tree" id="fmTree">
        <div style="padding:12px;color:#8aa0bd;font-size:12px;">載入中...</div>
      </div>
    </div>
  </div>
 </aside>

<section class="fm-main">
  <div class="fm-head">
    <div>
      <div class="fm-title">檔案管理</div>
      <div class="fm-sub">用接近資料夾總管的方式瀏覽、搜尋、上傳與管理檔案</div>
    </div>
    <div class="fm-stats">
      <div class="fm-stat"><i class="fas fa-folder" style="color:#1677ff;"></i> <asp:Label ID="lbl資料夾數" runat="server" Text="0" /> 個資料夾</div>
      <div class="fm-stat"><i class="fas fa-file" style="color:#8c8c8c;"></i> <asp:Label ID="lbl檔案數" runat="server" Text="0" /> 個檔案</div>
    </div>
  </div>

  <!-- 麵包屑 -->
  <div class="fm-bc">
    <button type="button" class="bc-link" onclick="navTo('')"><i class="fas fa-home" style="font-size:12px;"></i> 根目錄</button>
    <asp:Literal ID="litBC" runat="server" />
  </div>

  <div class="fm-toolbar">
    <!-- 工具列 -->
    <div class="fm-bar">
      <div class="fm-search">
        <i class="fas fa-search"></i>
        <input type="text" id="searchInp" placeholder="搜尋目前資料夾中的檔案或資料夾..." oninput="queueSearch(this.value)">
      </div>
      <div class="fm-chip"><i class="fas fa-layer-group"></i> <span id="zoneBadge"></span></div>
      <div class="view-group">
        <button type="button" class="vb on" id="vGrid" onclick="setView('grid')" title="格狀"><i class="fas fa-th"></i></button>
        <button type="button" class="vb"    id="vList" onclick="setView('list')" title="清單"><i class="fas fa-list"></i></button>
      </div>
      <button type="button" class="btn-add" onclick="showAddMenu(event)">
        <i class="fas fa-plus"></i> 新增
      </button>
      <!-- 新增下拉 -->
      <div id="addMenu" style="display:none;position:fixed;background:#fff;border:1px solid #f0f0f0;border-radius:8px;box-shadow:0 4px 16px rgba(0,0,0,.12);min-width:160px;z-index:9000;padding:4px 0;">
        <div class="ctx-item" onclick="hideAddMenu();showNewFolder()"><i class="fas fa-folder-plus" style="color:#1677ff;"></i> 新增資料夾</div>
        <div class="ctx-sep"></div>
        <label class="ctx-item" style="cursor:pointer;">
          <i class="fas fa-upload" style="color:#52c41a;"></i> 上傳檔案
          <input type="file" id="fileInput" multiple style="display:none;" onchange="doUpload(this.files)">
        </label>
      </div>
    </div>
    <div class="fm-summary">
      <div class="fm-summary-text" id="resultMeta">目前顯示全部項目</div>
      <div class="fm-summary-actions">
        <button type="button" class="bc-link" onclick="clearSearch()" style="font-size:12px;">清除搜尋</button>
      </div>
    </div>
  </div>

<!-- 右鍵選單 -->
<div id="ctxMenu" class="ctx-menu">
  <div id="ctx-open"   class="ctx-item" onclick="ctxDo('open')"  ><i class="fas fa-folder-open" style="color:#1677ff;"></i> 開啟</div>
  <div id="ctx-dl"     class="ctx-item" onclick="ctxDo('dl')"    ><i class="fas fa-download"></i> 下載</div>
  <div id="ctx-prev"   class="ctx-item" onclick="ctxDo('prev')"  ><i class="fas fa-eye"></i> 預覽</div>
  <div class="ctx-sep"></div>
  <div id="ctx-rename" class="ctx-item" onclick="ctxDo('rename')"><i class="fas fa-i-cursor"></i> 重新命名</div>
  <div class="ctx-sep"></div>
  <div id="ctx-del"    class="ctx-item red" onclick="ctxDo('del')"><i class="fas fa-trash"></i> 移至回收桶</div>
</div>

<!-- 新增資料夾 Modal -->
<div class="modal-wrap" id="newFolderModal">
  <div class="modal-box">
    <div class="modal-title"><i class="fas fa-folder-plus" style="color:#1677ff;margin-right:8px;"></i>新增資料夾</div>
    <input class="modal-inp" id="newFolderInp" type="text" placeholder="資料夾名稱"
           onkeydown="if(event.key==='Enter')confirmNewFolder();if(event.key==='Escape')closeNewFolder();">
    <div class="modal-btns">
      <button type="button" class="mbtn" onclick="closeNewFolder()">取消</button>
      <button type="button" class="mbtn primary" onclick="confirmNewFolder()">建立</button>
    </div>
  </div>
</div>

<!-- 上傳進度 -->
<div class="up-toast" id="upToast">
  <div class="ut-head">
    <span id="upTitle">上傳中...</span>
    <button type="button" onclick="this.closest('.up-toast').classList.remove('on')" style="background:none;border:none;color:#fff;cursor:pointer;font-size:16px;">×</button>
  </div>
  <div id="upList"></div>
</div>

<!-- 預覽 -->
<div class="prev-wrap" id="prevWrap">
  <div class="prev-box">
    <div class="prev-head">
      <span id="prevTitle" style="font-weight:700;font-size:14px;"></span>
      <button type="button" onclick="closePrev()" style="padding:5px 14px;border-radius:6px;border:1px solid #d9d9d9;background:#fff;cursor:pointer;font-size:13px;">✕ 關閉</button>
    </div>
    <div style="flex:1;overflow:auto;padding:14px;" id="prevBody"></div>
  </div>
</div>

<!-- 格狀容器 -->
<div id="gridArea" style="position:relative;"
     ondragover="event.preventDefault();this.classList.add('drop-over')"
     ondragleave="this.classList.remove('drop-over')"
     ondrop="this.classList.remove('drop-over');onDrop(event)">

  <!-- 格狀 -->
  <div class="fm-grid" id="fmGrid">
    <!-- 資料夾 -->
    <asp:Repeater ID="rptFolders" runat="server">
    <ItemTemplate>
      <div class="fm-card" data-type="folder" data-id="<%# Eval("資料夾編號") %>" data-name="<%# Eval("資料夾名稱") %>"
           onclick="selectCard(this,event)"
           ondblclick="navTo(<%# Eval("資料夾編號") %>)"
           oncontextmenu="showCtx(event,this,'folder')">
        <span class="ico"><i class="fas fa-folder ico-folder" style="font-size:44px;"></i></span>
        <div class="nm"><%# Eval("資料夾名稱") %></div>
        <div class="info">系統資料夾</div>
        <div class="badge-row">
          <span class="fm-badge b-sys"><%# Eval("建立者") %></span>
          <%# Convert.ToInt32(Eval("子項目數"))>0 ? "<span class='fm-badge b-sys'>"+Eval("子項目數")+"個項目</span>" : "" %>
        </div>
      </div>
    </ItemTemplate>
    </asp:Repeater>
    <!-- 檔案 -->
    <asp:Repeater ID="rptFilesGrid" runat="server">
    <ItemTemplate>
      <div class="fm-card" data-type="file" data-id="<%# Eval("檔案編號") %>" data-name="<%# Eval("原始檔名") %>"
           data-ext="<%# Eval("副檔名") %>" data-perm="<%# Eval("儲存區類型").ToString()=="永久區"?"1":"0" %>"
           data-grp="<%# Eval("組別編號") %>"
           onclick="selectCard(this,event)"
           ondblclick="doPreviewById(<%# Eval("檔案編號") %>,'<%# Eval("副檔名") %>','<%# Server.HtmlEncode(Eval("原始檔名").ToString()) %>')"
           oncontextmenu="showCtx(event,this,'file')">
        <span class="ico"><%# 取得圖示(Convert.ToString(Eval("副檔名"))) %></span>
        <div class="nm"><%# Eval("原始檔名") %></div>
        <div class="info"><%# 格式化大小(Eval("檔案大小")) %></div>
        <div class="badge-row">
          <span class="fm-badge <%# Eval("儲存區類型").ToString()=="永久區"?"b-perm":"b-temp" %>">
            <%# Eval("儲存區類型").ToString()=="永久區"?"永久":"時效" %>
          </span>
          <%# 取得狀態Badge(Eval("審核狀態").ToString(), Eval("到期時間"), Eval("儲存區類型").ToString()) %>
        </div>
      </div>
    </ItemTemplate>
    </asp:Repeater>
  </div>

  <!-- 清單 -->
  <div id="fmListWrap" style="display:none;background:#fff;border:1px solid #f0f0f0;border-radius:8px;overflow:hidden;">
    <div class="fm-list-head">
      <div>名稱</div><div>組別</div><div>大小</div><div>上傳時間</div><div>狀態</div><div>操作</div>
    </div>
    <div id="fmListBody">
      <asp:Repeater ID="rptFilesList" runat="server">
      <ItemTemplate>
        <div class="fm-list-row" data-type="file" data-id="<%# Eval("檔案編號") %>" data-name="<%# Eval("原始檔名") %>"
             data-perm="<%# Eval("儲存區類型").ToString()=="永久區"?"1":"0" %>" data-grp="<%# Eval("組別編號") %>"
             onclick="selectCard(this,event)"
             ondblclick="doPreviewById(<%# Eval("檔案編號") %>,'<%# Eval("副檔名") %>','<%# Server.HtmlEncode(Eval("原始檔名").ToString()) %>')"
             oncontextmenu="showCtx(event,this,'file')">
          <div class="fn-cell">
            <span class="fn-ico"><%# 取得圖示(Convert.ToString(Eval("副檔名"))) %></span>
            <div>
              <div class="fn-name"><%# Eval("原始檔名") %></div>
              <div class="fn-sub">上傳者：<%# Eval("上傳者姓名") %></div>
            </div>
          </div>
          <div><span style="font-size:11px;background:#e6f0ff;color:#1677ff;padding:2px 7px;border-radius:4px;font-weight:600;"><%# Eval("組別名稱") %></span></div>
          <div style="color:#8c8c8c;font-size:12px;"><%# 格式化大小(Eval("檔案大小")) %></div>
          <div style="font-size:12px;color:#8c8c8c;"><%# Eval("上傳時間")==DBNull.Value?"-":民國日期.轉換日期(Convert.ToDateTime(Eval("上傳時間"))) %></div>
          <div><%# 取得狀態Badge(Eval("審核狀態").ToString(), Eval("到期時間"), Eval("儲存區類型").ToString()) %></div>
          <div>
            <button type="button" onclick="event.stopPropagation();doDownloadById(<%# Eval("檔案編號") %>)" style="background:none;border:none;cursor:pointer;color:#8c8c8c;font-size:14px;padding:4px;" title="下載"><i class="fas fa-download"></i></button>
          </div>
        </div>
      </ItemTemplate>
      </asp:Repeater>
    </div>
  </div>

  <!-- 空狀態 -->
  <asp:Panel ID="pnlEmpty" runat="server" Visible="false">
    <div class="empty-box">
      <i class="fas fa-folder-open ei"></i>
      <p style="font-size:15px;margin-bottom:8px;">此資料夾是空的</p>
      <p style="font-size:13px;">點擊「新增」上傳檔案或建立資料夾</p>
    </div>
  </asp:Panel>
</div>

<!-- PostBack 控件 -->
<asp:HiddenField ID="hfAct"  runat="server" />
<asp:HiddenField ID="hfData" runat="server" />
<asp:Button ID="btnPB" runat="server" Style="display:none;" OnClick="btnPB_Click" />
<input type="hidden" id="__fid"  value="<asp:Literal ID='litFid'  runat='server' />">
<input type="hidden" id="__zone" value="<asp:Literal ID='litZone' runat='server' />">
</div>
</section>
</div>

<script>
var FID  = document.getElementById('__fid').value;
var ZONE = document.getElementById('__zone').value || '永久區';
var VIEW = localStorage.getItem('fmView') || 'grid';
var SEL  = null;
var SEARCH_TIMER = null;
var TREE_CACHE = {};

// ── 導覽 ─────────────────────────────────────────────────
function navTo(fid) {
  var url = '檔案瀏覽.aspx?zone='+encodeURIComponent(ZONE);
  if(fid) url += '&fid='+fid;
  location.href = url;
}

// ── 檢視切換 ─────────────────────────────────────────────
function setView(v) {
  VIEW = v;
  localStorage.setItem('fmView', v);
  document.getElementById('vGrid').className = 'vb'+(v==='grid'?' on':'');
  document.getElementById('vList').className = 'vb'+(v==='list'?' on':'');
  document.getElementById('fmGrid').style.display      = v==='grid'?'grid':'none';
  document.getElementById('fmListWrap').style.display  = v==='list'?'block':'none';
}

// ── 選取 ─────────────────────────────────────────────────
function selectCard(el, e) {
  document.querySelectorAll('.fm-card.sel,.fm-list-row.sel').forEach(function(x){x.classList.remove('sel');});
  el.classList.add('sel');
  SEL = { type:el.dataset.type, id:el.dataset.id, name:el.dataset.name,
          ext:el.dataset.ext, perm:el.dataset.perm==='1', grp:el.dataset.grp };
  e.stopPropagation();
}
document.addEventListener('click', function(){
  document.querySelectorAll('.fm-card.sel,.fm-list-row.sel').forEach(function(x){x.classList.remove('sel');});
  SEL=null; hideCtxMenu(); hideAddMenu();
});

// ── 右鍵選單 ─────────────────────────────────────────────
function showCtx(e, el, type) {
  e.preventDefault(); e.stopPropagation();
  selectCard(el, e);
  document.getElementById('ctx-open').style.display   = type==='folder'?'flex':'none';
  document.getElementById('ctx-dl').style.display     = type==='file'?'flex':'none';
  document.getElementById('ctx-prev').style.display   = type==='file'?'flex':'none';
  document.getElementById('ctx-rename').style.display = type==='folder'?'flex':'none';
  // 永久區且無權限：隱藏刪除
  var canDel = type==='folder' || !SEL.perm;
  document.getElementById('ctx-del').style.display = canDel?'flex':'none';

  var m = document.getElementById('ctxMenu');
  m.style.left = Math.min(e.clientX, window.innerWidth-170)+'px';
  m.style.top  = Math.min(e.clientY, window.innerHeight-180)+'px';
  m.classList.add('on');
}
function hideCtxMenu(){ document.getElementById('ctxMenu').classList.remove('on'); }
document.addEventListener('contextmenu', function(e){ if(!e.target.closest('#ctxMenu')) hideCtxMenu(); });

function ctxDo(act) {
  hideCtxMenu();
  if(!SEL) return;
  if(act==='open')   { navTo(SEL.id); return; }
  if(act==='dl')     { doDownloadById(SEL.id); return; }
  if(act==='prev')   { doPreviewById(SEL.id, SEL.ext, SEL.name); return; }
  if(act==='rename') { doRename(); return; }
  if(act==='del')    { doDeleteById(SEL.id, SEL.name, SEL.type, SEL.perm); }
}

// ── 新增按鈕 ─────────────────────────────────────────────
function showAddMenu(e){
  e.stopPropagation();
  var m=document.getElementById('addMenu'), btn=e.currentTarget;
  var r=btn.getBoundingClientRect();
  m.style.left=r.left+'px'; m.style.top=(r.bottom+4)+'px';
  m.style.display='block';
}
function hideAddMenu(){ document.getElementById('addMenu').style.display='none'; }

// ── 新增資料夾 ───────────────────────────────────────────
function showNewFolder(){
  if(!FID){ alert('請先進入一個資料夾再新增子資料夾'); return; }
  var m=document.getElementById('newFolderModal');
  m.classList.add('on');
  var inp=document.getElementById('newFolderInp');
  inp.value=''; setTimeout(function(){inp.focus();},100);
}
function closeNewFolder(){ document.getElementById('newFolderModal').classList.remove('on'); }
function confirmNewFolder(){
  var n=document.getElementById('newFolderInp').value.trim();
  if(!n){ alert('請輸入名稱'); return; }
  closeNewFolder();
  pb('newFolder', FID+'|'+n);
}

// ── 重新命名 ─────────────────────────────────────────────
function doRename(){
  if(!SEL || SEL.type!=='folder') return;
  var n=prompt('輸入新名稱：', SEL.name);
  if(n && n.trim() && n.trim()!==SEL.name) pb('rename', SEL.id+'|'+n.trim());
}

// ── 刪除 ─────────────────────────────────────────────────
function doDeleteById(id, name, type, isPerm){
  if(isPerm && type==='file'){ alert('永久區檔案不可自行刪除'); return; }
  var msg = type==='folder' ? '刪除資料夾「'+name+'」將連同所有內容移至回收桶？' : '將「'+name+'」移至回收桶？';
  if(!confirm(msg)) return;
  pb(type==='folder'?'delFolder':'delFile', id);
}

// ── 下載/預覽 ────────────────────────────────────────────
function doDownloadById(id){ location.href='Handlers/下載.ashx?id='+id; }
function doPreviewById(id, ext, name){
  document.getElementById('prevTitle').textContent = name;
  var body = document.getElementById('prevBody');
  var supported=['.pdf','.jpg','.jpeg','.png','.gif','.bmp','.txt','.html'];
  body.innerHTML = supported.indexOf((ext||'').toLowerCase())>=0
    ? '<iframe src="Handlers/預覽.ashx?id='+id+'" style="width:100%;height:100%;border:none;min-height:500px;"></iframe>'
    : '<div style="text-align:center;padding:60px;color:#8c8c8c;"><i class="fas fa-file fa-3x" style="opacity:.2;display:block;margin-bottom:14px;"></i><p style="margin-bottom:14px;">不支援預覽此格式</p><a href="Handlers/下載.ashx?id='+id+'" style="display:inline-flex;align-items:center;gap:6px;padding:8px 18px;background:#1677ff;color:#fff;border-radius:8px;text-decoration:none;font-size:13px;font-weight:600;"><i class="fas fa-download"></i>下載查看</a></div>';
  document.getElementById('prevWrap').style.display='block';
  fetch('Handlers/預覽.ashx?id='+id+'&action=log');
}
function closePrev(){ document.getElementById('prevWrap').style.display='none'; document.getElementById('prevBody').innerHTML=''; }

// ── 拖放上傳 ─────────────────────────────────────────────
function onDrop(e){
  e.preventDefault();
  if(!FID){ alert('請先進入一個資料夾'); return; }
  if(e.dataTransfer.files.length) doUpload(e.dataTransfer.files);
}

// ── 上傳 ─────────────────────────────────────────────────
function doUpload(files){
  if(!FID){ alert('請先進入一個資料夾再上傳'); return; }
  var toast=document.getElementById('upToast'), list=document.getElementById('upList');
  toast.classList.add('on'); list.innerHTML='';
  document.getElementById('upTitle').textContent='上傳 '+files.length+' 個檔案...';
  var done=0;
  Array.from(files).forEach(function(file,idx){
    var sid='u'+idx+'_'+Date.now();
    var item=document.createElement('div'); item.className='ut-item';
    item.innerHTML='<div style="display:flex;justify-content:space-between;"><span style="max-width:200px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;">'+esc(file.name)+'</span><span id="st'+sid+'" style="color:#8c8c8c;font-size:11px;">準備中</span></div><div class="ut-bar"><div class="ut-fill" id="bar'+sid+'" style="width:0%"></div></div>';
    list.appendChild(item);
    var fd=new FormData(); fd.append('fid', FID); fd.append('file', file);
    var xhr=new XMLHttpRequest();
    xhr.upload.onprogress=function(e){ if(e.lengthComputable){ var p=Math.round(e.loaded/e.total*100); var b=document.getElementById('bar'+sid); if(b)b.style.width=p+'%'; var s=document.getElementById('st'+sid); if(s)s.textContent=p+'%'; } };
    xhr.onload=function(){
      done++;
      try{ var res=JSON.parse(xhr.responseText); var s=document.getElementById('st'+sid); if(s){s.textContent=res.ok?'✓ 完成':'✗ '+res.msg; s.style.color=res.ok?'#52c41a':'#ff4d4f';} }catch(ex){}
      if(done===files.length){ document.getElementById('upTitle').textContent='✓ 完成！'; setTimeout(function(){toast.classList.remove('on');list.innerHTML='';location.reload();},2000); }
    };
    xhr.open('POST','Handlers/上傳.ashx'); xhr.send(fd);
  });
}

// ── 搜尋 ─────────────────────────────────────────────────
function doSearch(kw){
  kw=kw.toLowerCase();
  var shown=0;
  document.querySelectorAll('.fm-card').forEach(function(el){
    var ok=!kw||(el.dataset.name||'').toLowerCase().includes(kw);
    el.classList.toggle('fm-hidden', !ok);
    if(ok) shown++;
  });
  document.querySelectorAll('.fm-list-row').forEach(function(el){
    var ok=!kw||(el.dataset.name||'').toLowerCase().includes(kw);
    el.classList.toggle('fm-hidden', !ok);
  });
  document.getElementById('resultMeta').textContent = kw ? ('搜尋結果：'+shown+' 個項目') : '目前顯示全部項目';
}
function queueSearch(value){
  clearTimeout(SEARCH_TIMER);
  SEARCH_TIMER = setTimeout(function(){ doSearch(value); }, 120);
}
function clearSearch(){
  var inp=document.getElementById('searchInp');
  inp.value='';
  doSearch('');
}

// ── 資料夾樹 ─────────────────────────────────────────────
function reloadTree(){
  TREE_CACHE={};
  renderTree(null, document.getElementById('fmTree'), true);
}
function renderTree(parentId, host, expandCurrent){
  var key = parentId || 'root';
  if (TREE_CACHE[key]) return paintTree(TREE_CACHE[key], host, expandCurrent);
  host.innerHTML = '<div style="padding:10px;color:#8aa0bd;font-size:12px;">載入中...</div>';
  fetch('Handlers/資料夾樹.ashx?儲存區='+encodeURIComponent(ZONE)+(parentId ? '&父id='+parentId : ''))
    .then(function(r){ return r.json(); })
    .then(function(data){
      TREE_CACHE[key] = Array.isArray(data) ? data : [];
      paintTree(TREE_CACHE[key], host, expandCurrent);
    })
    .catch(function(){
      host.innerHTML = '<div style="padding:10px;color:#cf1322;font-size:12px;">資料夾樹載入失敗</div>';
    });
}
function paintTree(data, host, expandCurrent){
  if (!data || !data.length){
    host.innerHTML = '<div style="padding:10px;color:#8aa0bd;font-size:12px;">目前沒有可顯示的子資料夾</div>';
    return;
  }
  host.innerHTML = '';
  data.forEach(function(item){
    var wrap=document.createElement('div');
    var node=document.createElement('div');
    node.className='tree-node'+(String(item.id)===String(FID)?' on':'');
    node.dataset.id=item.id;
    node.innerHTML=
      '<span class="tri'+(item.children?'':' empty')+'"><i class="fas '+(item.children?'fa-chevron-right':'fa-circle')+'"></i></span>'+
      '<i class="fas fa-folder" style="color:#1677ff;"></i>'+
      '<span class="label">'+esc(item.text)+'</span>'+
      '<span class="count">'+(item.files || 0)+'</span>';
    var children=document.createElement('div');
    children.className='tree-children';
    var tri=node.querySelector('.tri');
    node.addEventListener('click', function(e){
      if (e.target.closest('.tri') && item.children){
        toggleTree(item.id, children, tri);
        return;
      }
      navTo(item.id);
    });
    wrap.appendChild(node);
    wrap.appendChild(children);
    host.appendChild(wrap);

    if (expandCurrent && String(item.id)===String(FID)){
      if (item.children){
        children.classList.add('on');
        tri.innerHTML='<i class="fas fa-chevron-down"></i>';
        renderTree(item.id, children, true);
      }
    }
  });
}
function toggleTree(id, children, tri){
  var open = children.classList.contains('on');
  children.classList.toggle('on', !open);
  tri.innerHTML='<i class="fas '+(!open?'fa-chevron-down':'fa-chevron-right')+'"></i>';
  if (!open && !children.dataset.loaded){
    renderTree(id, children, false);
    children.dataset.loaded='1';
  }
}
function initExplorerUI(){
  document.getElementById('zoneBadge').textContent = ZONE;
  document.getElementById('quickZoneLabel').textContent = ZONE + ' 根目錄';
  document.getElementById('quickRoot').classList.toggle('on', !FID);
  document.getElementById('quickZone').classList.toggle('on', !FID);
  setView(VIEW);
  doSearch('');
  reloadTree();
}

// ── PostBack ─────────────────────────────────────────────
function pb(act, data){
  document.getElementById('<%= hfAct.ClientID %>').value = act;
  document.getElementById('<%= hfData.ClientID %>').value = data||'';
  document.getElementById('<%= btnPB.ClientID %>').click();
}
function esc(s){ return (s||'').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;'); }
initExplorerUI();
</script>
</asp:Content>
