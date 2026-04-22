<%@ Page Language="C#" MasterPageFile="~/主版面.master" AutoEventWireup="true" CodeFile="檔案上傳.aspx.cs" Inherits="檔案上傳" Title="上傳檔案" %>
<asp:Content ID="Content1" ContentPlaceHolderID="主內容" runat="server">
<style>
.folder-tree-item {
    display:flex; align-items:center; padding:8px 12px;
    cursor:pointer; border-radius:6px; transition:background 0.15s;
    border:2px solid transparent; margin-bottom:3px;
}
.folder-tree-item:hover { background:#f0f5ff; }
.folder-tree-item.selected {
    background:#eff6ff; border-color:#3b82f6;
}
.folder-tree-item .folder-icon { font-size:18px; flex-shrink:0; margin-right:10px; }
.folder-tree-item .folder-name { font-size:13px; font-weight:500; flex:1; }
.folder-tree-item .folder-meta { font-size:11px; color:#9ca3af; }
.step-badge {
    width:28px; height:28px; border-radius:50%;
    background:#1a3a6b; color:white;
    display:inline-flex; align-items:center; justify-content:center;
    font-size:13px; font-weight:700; flex-shrink:0; margin-right:10px;
}
.step-done { background:#2e7d52; }
.step-card {
    border:2px solid #e5eaf2; border-radius:12px;
    padding:20px; margin-bottom:16px; transition:border-color 0.2s;
}
.step-card.active { border-color:#3b82f6; }
.step-card.done { border-color:#2e7d52; }
</style>

<div class="page-header">
    <div>
        <div class="page-title"><i class="fas fa-upload" style="color:#1a3a6b;margin-right:10px;"></i>上傳檔案</div>
        <div class="page-breadcrumb">文件管理系統 / 上傳檔案</div>
    </div>
</div>

<asp:Panel ID="pnl訊息" runat="server" Visible="false">
    <div class="alert alert-success" style="margin-bottom:16px;">
        <i class="fas fa-check-circle"></i> <asp:Label ID="lbl成功訊息" runat="server" />
        <div style="margin-top:8px;">
            <a href='<%# "檔案瀏覽.aspx?fid=" + hf目標資料夾.Value %>' class="btn btn-primary btn-sm">
                <i class="fas fa-folder-open"></i> 前往查看
            </a>
            <button type="button" onclick="location.reload()" class="btn btn-outline btn-sm" style="margin-left:6px;">
                繼續上傳
            </button>
        </div>
    </div>
</asp:Panel>
<asp:Panel ID="pnl錯誤" runat="server" Visible="false">
    <div class="alert alert-danger" style="margin-bottom:16px;">
        <i class="fas fa-exclamation-circle"></i> <asp:Label ID="lbl錯誤訊息" runat="server" />
    </div>
</asp:Panel>

<div style="display:grid;grid-template-columns:1fr 380px;gap:20px;align-items:start;">

<!-- 左側：三步驟流程 -->
<div>

<!-- Step 1：選擇目標資料夾 -->
<div class="step-card" id="step1Card">
    <div style="display:flex;align-items:center;margin-bottom:14px;">
        <span class="step-badge" id="badge1">1</span>
        <div>
            <div style="font-weight:700;font-size:15px;color:#1a3a6b;">選擇目標資料夾</div>
            <div style="font-size:12px;color:#6b7280;">選擇要將檔案上傳到哪個資料夾</div>
        </div>
    </div>

    <!-- 儲存區切換 -->
    <div style="display:flex;gap:6px;margin-bottom:12px;">
        <button type="button" id="btn永久" onclick="切換儲存區('永久區')"
                style="flex:1;padding:8px;border-radius:8px;border:2px solid #1a3a6b;
                       background:#1a3a6b;color:white;cursor:pointer;font-size:13px;font-family:inherit;">
            🏛️ 永久區
        </button>
        <button type="button" id="btn時效" onclick="切換儲存區('時效區')"
                style="flex:1;padding:8px;border-radius:8px;border:2px solid #e5eaf2;
                       background:white;color:#374151;cursor:pointer;font-size:13px;font-family:inherit;">
            🕐 時效區
        </button>
    </div>

    <!-- 已選擇顯示 -->
    <div id="divSelected" style="display:none;padding:10px 14px;background:#eff6ff;
         border-radius:8px;margin-bottom:10px;display:flex;align-items:center;gap:10px;">
        <span style="font-size:20px;">📁</span>
        <div style="flex:1;">
            <div style="font-size:13px;font-weight:600;color:#1a3a6b;" id="spanSelectedName">-</div>
            <div style="font-size:11px;color:#6b7280;" id="spanSelectedPath">-</div>
        </div>
        <button type="button" onclick="清除選擇()" style="background:none;border:none;color:#9ca3af;cursor:pointer;font-size:12px;">✕ 重選</button>
    </div>

    <!-- 資料夾樹 -->
    <div id="divTree" style="border:1.5px solid #e5eaf2;border-radius:10px;
         max-height:380px;overflow-y:auto;padding:8px;">
        <asp:Repeater ID="rpt資料夾選擇" runat="server">
        <ItemTemplate>
            <div class="folder-tree-item"
                 data-id="<%# Eval("資料夾編號") %>"
                 data-name="<%# System.Web.HttpUtility.HtmlAttributeEncode(Eval("資料夾名稱").ToString()) %>"
                 data-type="<%# Eval("儲存區類型") %>"
                 data-storage="<%# Eval("儲存區類型") %>"
                 onclick="選擇資料夾(this)"
                 style="padding-left:<%# (Convert.ToInt32(Eval("層級"))*20+8) %>px;">
                <span class="folder-icon"><%# Convert.ToInt32(Eval("層級"))==0 ? "🗂️" : (Convert.ToInt32(Eval("層級"))==1 ? "📂" : "📁") %></span>
                <div class="folder-name"><%# Eval("資料夾名稱") %></div>
                <div class="folder-meta">
                    <%# Eval("子資料夾數") %>資料夾 · <%# Eval("檔案數") %>檔
                </div>
            </div>
        </ItemTemplate>
        </asp:Repeater>
    </div>
    <asp:HiddenField ID="hf目標資料夾" runat="server" />
    <asp:HiddenField ID="hf目標儲存區" runat="server" />
</div>

<!-- Step 2：選擇檔案 -->
<div class="step-card" id="step2Card" style="opacity:0.5;">
    <div style="display:flex;align-items:center;margin-bottom:14px;">
        <span class="step-badge" id="badge2">2</span>
        <div>
            <div style="font-weight:700;font-size:15px;color:#1a3a6b;">選擇要上傳的檔案</div>
            <div style="font-size:12px;color:#6b7280;">點擊或拖放檔案</div>
        </div>
    </div>
    <div class="upload-zone" id="uploadZone" onclick="document.getElementById('<%= fu檔案.ClientID %>').click();"
         style="pointer-events:none;opacity:0.6;">
        <i class="fas fa-cloud-upload-alt"></i>
        <p style="font-size:15px;font-weight:600;color:#1a3a6b;margin-bottom:4px;">點擊或拖放檔案</p>
        <p style="font-size:12px;color:#6b7280;">支援所有格式，最大 500MB</p>
        <asp:FileUpload ID="fu檔案" runat="server" Style="display:none;" onchange="檔案已選(this)" />
    </div>
    <div id="divFileInfo" style="display:none;margin-top:10px;padding:10px 14px;
         background:#f0fdf4;border-radius:8px;display:flex;align-items:center;gap:10px;">
        <span style="font-size:24px;" id="spanFileIcon">📄</span>
        <div style="flex:1;">
            <div style="font-size:13px;font-weight:600;" id="spanFileName">-</div>
            <div style="font-size:11px;color:#6b7280;" id="spanFileSize">-</div>
        </div>
        <button type="button" onclick="清除檔案()" style="background:none;border:none;color:#9ca3af;cursor:pointer;">✕</button>
    </div>
</div>

<!-- Step 3：描述與上傳 -->
<div class="step-card" id="step3Card" style="opacity:0.5;">
    <div style="display:flex;align-items:center;margin-bottom:14px;">
        <span class="step-badge" id="badge3">3</span>
        <div>
            <div style="font-weight:700;font-size:15px;color:#1a3a6b;">描述（選填）與上傳</div>
            <div style="font-size:12px;color:#6b7280;">加入描述幫助他人了解檔案內容</div>
        </div>
    </div>
    <asp:TextBox ID="txt描述" runat="server" CssClass="form-control" TextMode="MultiLine" Rows="2"
                 placeholder="輸入檔案說明..." Style="margin-bottom:14px;" />
    <asp:Button ID="btn上傳" runat="server" Text="🚀 開始上傳" CssClass="btn btn-accent"
                Style="font-size:15px;padding:12px 32px;width:100%;" OnClick="btn上傳_Click" Enabled="false" />
    <div id="divUploadSummary" style="display:none;margin-top:12px;padding:10px 14px;
         background:#f8faff;border-radius:8px;font-size:12px;color:#374151;line-height:1.8;">
    </div>
</div>

</div>

<!-- 右側：說明與權限 -->
<div>
    <div class="card" style="margin-bottom:14px;">
        <h4 style="font-size:14px;font-weight:700;color:#1a3a6b;margin-bottom:14px;">
            <i class="fas fa-info-circle" style="margin-right:7px;"></i>儲存區說明
        </h4>
        <div style="font-size:13px;line-height:2;">
            <div style="background:#f0f5ff;border-radius:8px;padding:10px 14px;margin-bottom:10px;">
                <div style="font-weight:700;margin-bottom:4px;">🏛️ 永久區</div>
                <div style="color:#6b7280;font-size:12px;">
                    上傳後需組別負責人審核<br>
                    審核通過後永久保存<br>
                    <b style="color:#dc2626;">上傳後不可自行刪除</b>
                </div>
            </div>
            <div style="background:#fff7ed;border-radius:8px;padding:10px 14px;">
                <div style="font-weight:700;margin-bottom:4px;">🕐 時效區</div>
                <div style="color:#6b7280;font-size:12px;">
                    不需審核，上傳即可使用<br>
                    保存 30 天後自動移入回收桶<br>
                    適合臨時共享的文件
                </div>
            </div>
        </div>
    </div>

    <div class="card" style="margin-bottom:14px;">
        <h4 style="font-size:14px;font-weight:700;color:#1a3a6b;margin-bottom:12px;">
            <i class="fas fa-user-shield" style="margin-right:7px;"></i>您的權限
        </h4>
        <table style="width:100%;font-size:13px;border-collapse:collapse;">
            <tr>
                <td style="padding:4px 0;color:#6b7280;">您的 IP</td>
                <td style="padding:4px 0;font-weight:600;font-family:monospace;">
                    <asp:Label ID="lbl您的IP" runat="server" />
                </td>
            </tr>
            <tr>
                <td style="padding:4px 0;color:#6b7280;">執行檔上傳</td>
                <td style="padding:4px 0;"><asp:Label ID="lbl執行檔權限" runat="server" /></td>
            </tr>
            <tr>
                <td style="padding:4px 0;color:#6b7280;">角色</td>
                <td style="padding:4px 0;font-weight:600;">
                    <asp:Label ID="lbl角色" runat="server" />
                </td>
            </tr>
        </table>
    </div>

    <div class="card">
        <h4 style="font-size:14px;font-weight:700;color:#1a3a6b;margin-bottom:10px;">
            <i class="fas fa-lightbulb" style="margin-right:7px;"></i>快速上傳
        </h4>
        <p style="font-size:12px;color:#6b7280;line-height:1.8;">
            也可以在<a href="檔案瀏覽.aspx" style="color:#1a3a6b;font-weight:600;">檔案瀏覽</a>頁面先進入目標資料夾，
            再點右上角「上傳到此資料夾」，系統會自動帶入目標資料夾。
        </p>
        <a href="資料夾管理.aspx" class="btn btn-outline btn-sm" style="margin-top:10px;display:inline-flex;">
            <i class="fas fa-folder-plus"></i> 新增資料夾
        </a>
    </div>
</div>

</div>

<script>
var 目前儲存區 = '永久區';
var 已選資料夾 = false;
var 已選檔案 = false;

// ── 儲存區切換 ───────────────────────────────────────────────
function 切換儲存區(type) {
    目前儲存區 = type;
    document.getElementById('btn永久').style.background = type==='永久區' ? '#1a3a6b' : 'white';
    document.getElementById('btn永久').style.color = type==='永久區' ? 'white' : '#374151';
    document.getElementById('btn永久').style.borderColor = type==='永久區' ? '#1a3a6b' : '#e5eaf2';
    document.getElementById('btn時效').style.background = type==='時效區' ? '#e67e22' : 'white';
    document.getElementById('btn時效').style.color = type==='時效區' ? 'white' : '#374151';
    document.getElementById('btn時效').style.borderColor = type==='時效區' ? '#e67e22' : '#e5eaf2';

    // 過濾樹節點
    var items = document.querySelectorAll('.folder-tree-item');
    items.forEach(function(item) {
        item.style.display = item.dataset.storage === type ? 'flex' : 'none';
    });
    清除選擇();
}

// ── 資料夾選擇 ───────────────────────────────────────────────
function 選擇資料夾(el) {
    // 移除其他選中
    document.querySelectorAll('.folder-tree-item.selected').forEach(function(e) {
        e.classList.remove('selected');
    });
    el.classList.add('selected');

    var id = el.dataset.id;
    var name = el.dataset.name;
    // 建立完整路徑顯示
    var path = '';
    var cur = el;
    var parts = [name];
    // 往上找父層（簡易版，顯示縮排層數）
    var level = parseInt(el.style.paddingLeft) / 20;

    document.getElementById('hf_目標資料夾').value = id;
    document.getElementById('hf_目標儲存區').value = 目前儲存區;

    // 設定 ASP.NET hidden fields
    document.getElementById('<%= hf目標資料夾.ClientID %>').value = id;
    document.getElementById('<%= hf目標儲存區.ClientID %>').value = 目前儲存區;

    document.getElementById('spanSelectedName').textContent = name;
    document.getElementById('spanSelectedPath').textContent = 目前儲存區 + ' / ' + name;
    document.getElementById('divSelected').style.display = 'flex';

    已選資料夾 = true;
    更新步驟狀態();
}

function 清除選擇() {
    document.querySelectorAll('.folder-tree-item.selected').forEach(function(e) { e.classList.remove('selected'); });
    document.getElementById('divSelected').style.display = 'none';
    document.getElementById('<%= hf目標資料夾.ClientID %>').value = '';
    已選資料夾 = false;
    更新步驟狀態();
}

// ── 檔案選擇 ─────────────────────────────────────────────────
var 副檔名圖示 = {
    pdf:'📕', doc:'📘', docx:'📘', xls:'📗', xlsx:'📗',
    ppt:'📙', pptx:'📙', jpg:'🖼️', jpeg:'🖼️', png:'🖼️',
    gif:'🖼️', zip:'📦', rar:'📦', txt:'📝', mp4:'🎬'
};

function 檔案已選(input) {
    if (!input.files || !input.files[0]) return;
    var f = input.files[0];
    var ext = f.name.split('.').pop().toLowerCase();
    var icon = 副檔名圖示[ext] || '📄';
    var size = f.size < 1024*1024 ? (f.size/1024).toFixed(1)+' KB' : (f.size/1024/1024).toFixed(1)+' MB';

    document.getElementById('spanFileIcon').textContent = icon;
    document.getElementById('spanFileName').textContent = f.name;
    document.getElementById('spanFileSize').textContent = size;
    document.getElementById('divFileInfo').style.display = 'flex';

    已選檔案 = true;
    更新步驟狀態();
}

function 清除檔案() {
    document.getElementById('<%= fu檔案.ClientID %>').value = '';
    document.getElementById('divFileInfo').style.display = 'none';
    已選檔案 = false;
    更新步驟狀態();
}

// ── 步驟狀態更新 ─────────────────────────────────────────────
function 更新步驟狀態() {
    // Step1
    document.getElementById('step1Card').className = 'step-card' + (已選資料夾 ? ' done' : ' active');
    document.getElementById('badge1').className = 'step-badge' + (已選資料夾 ? ' step-done' : '');
    document.getElementById('badge1').textContent = 已選資料夾 ? '✓' : '1';

    // Step2：需先選資料夾
    document.getElementById('step2Card').style.opacity = 已選資料夾 ? '1' : '0.5';
    document.getElementById('uploadZone').style.pointerEvents = 已選資料夾 ? 'auto' : 'none';
    document.getElementById('uploadZone').style.opacity = 已選資料夾 ? '1' : '0.6';
    document.getElementById('step2Card').className = 'step-card' + (已選檔案 ? ' done' : (已選資料夾 ? ' active' : ''));
    document.getElementById('badge2').className = 'step-badge' + (已選檔案 ? ' step-done' : '');
    document.getElementById('badge2').textContent = 已選檔案 ? '✓' : '2';

    // Step3：需選資料夾+檔案
    var ready = 已選資料夾 && 已選檔案;
    document.getElementById('step3Card').style.opacity = ready ? '1' : '0.5';
    document.getElementById('step3Card').className = 'step-card' + (ready ? ' active' : '');
    document.getElementById('badge3').textContent = '3';

    // 上傳按鈕
    document.getElementById('<%= btn上傳.ClientID %>').disabled = !ready;

    // 摘要
    if (ready) {
        var sum = document.getElementById('divUploadSummary');
        sum.style.display = 'block';
        sum.innerHTML = '📁 <b>目標:</b> ' + document.getElementById('spanSelectedName').textContent +
            ' (' + 目前儲存區 + ')<br>' +
            '📄 <b>檔案:</b> ' + document.getElementById('spanFileName').textContent;
    } else {
        document.getElementById('divUploadSummary').style.display = 'none';
    }
}

// 初始化：依 QueryString 預選資料夾
window.addEventListener('load', function() {
    切換儲存區('永久區');

    // 若有預選的 fid（從瀏覽頁帶來）
    var preSelected = '<asp:Literal ID="litPreFid" runat="server" />';
    if (preSelected) {
        var el = document.querySelector('[data-id="' + preSelected + '"]');
        if (el) {
            el.scrollIntoView({ block:'center' });
            選擇資料夾(el);
        }
    }
});
</script>
<!-- 隱藏欄位（純 JS 操作用） -->
<input type="hidden" id="hf_目標資料夾" />
<input type="hidden" id="hf_目標儲存區" />
</asp:Content>
