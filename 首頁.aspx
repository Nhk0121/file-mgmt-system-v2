<%@ Page Language="C#" MasterPageFile="~/主版面.master" AutoEventWireup="true" CodeFile="首頁.aspx.cs" Inherits="首頁" Title="首頁" %>
<asp:Content ID="Content1" ContentPlaceHolderID="主內容" runat="server">

<div class="page-header">
    <div>
        <div class="page-title"><i class="fas fa-home" style="color:#1a3a6b;margin-right:10px;"></i>系統首頁</div>
        <div class="page-breadcrumb">文件管理系統 / 首頁</div>
    </div>
    <a href="檔案上傳.aspx" class="btn btn-accent">
        <i class="fas fa-upload"></i> 上傳新檔案
    </a>
</div>

<!-- 統計卡片 -->
<div class="stat-grid" style="margin-bottom:24px;">
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#1a3a6b,#2756a8);">
            <i class="fas fa-archive"></i>
        </div>
        <div>
            <div class="stat-value"><asp:Label ID="lbl永久區數量" runat="server" Text="0" /></div>
            <div class="stat-label">永久區檔案</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#e67e22,#f39c12);">
            <i class="fas fa-clock"></i>
        </div>
        <div>
            <div class="stat-value"><asp:Label ID="lbl時效區數量" runat="server" Text="0" /></div>
            <div class="stat-label">時效區檔案</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#f59e0b,#d97706);">
            <i class="fas fa-clipboard-check"></i>
        </div>
        <div>
            <div class="stat-value"><asp:Label ID="lbl待審核數量" runat="server" Text="0" /></div>
            <div class="stat-label">待審核檔案</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#dc2626,#b91c1c);">
            <i class="fas fa-exclamation-triangle"></i>
        </div>
        <div>
            <div class="stat-value"><asp:Label ID="lbl即將到期" runat="server" Text="0" /></div>
            <div class="stat-label">7天內到期</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#059669,#047857);">
            <i class="fas fa-download"></i>
        </div>
        <div>
            <div class="stat-value"><asp:Label ID="lbl今日下載" runat="server" Text="0" /></div>
            <div class="stat-label">今日下載次數</div>
        </div>
    </div>
    <div class="stat-card">
        <div class="stat-icon" style="background:linear-gradient(135deg,#7c3aed,#6d28d9);">
            <i class="fas fa-shield-alt"></i>
        </div>
        <div>
            <div class="stat-value"><asp:Label ID="lbl未處理資安" runat="server" Text="0" /></div>
            <div class="stat-label">未處理資安事件</div>
        </div>
    </div>
</div>

<!-- 兩欄佈局 -->
<div style="display:grid;grid-template-columns:1fr 1fr;gap:20px;">

<!-- 最近上傳 -->
<div class="card">
    <h3 style="font-size:15px;font-weight:700;color:#1a3a6b;margin-bottom:16px;">
        <i class="fas fa-upload" style="margin-right:8px;"></i>最近上傳
    </h3>
    <asp:Repeater ID="rpt最近上傳" runat="server">
    <ItemTemplate>
        <div style="display:flex;align-items:center;gap:10px;padding:10px 0;border-bottom:1px solid #f0f4f8;">
            <div style="width:36px;height:36px;background:#f0f4f8;border-radius:8px;display:flex;align-items:center;justify-content:center;color:#1a3a6b;font-size:16px;">
                <i class="fas <%# 取得檔案圖示(Convert.ToString(Eval("副檔名"))) %>"></i>
            </div>
            <div style="flex:1;min-width:0;">
                <div style="font-size:13px;font-weight:500;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;">
                    <%# Eval("原始檔名") %>
                </div>
                <div style="font-size:11px;color:#6b7280;">
                    <%# Eval("組別名稱") %> &bull; <%# 民國日期.轉換(Convert.ToDateTime(Eval("上傳時間"))) %>
                </div>
            </div>
            <span class="tag tag-<%# Eval("儲存區類型") %>"><%# Eval("儲存區類型") %></span>
        </div>
    </ItemTemplate>
    </asp:Repeater>
    <div style="text-align:right;margin-top:12px;">
        <a href="檔案瀏覽.aspx" class="btn btn-outline btn-sm">查看全部</a>
    </div>
</div>

<!-- 最近操作紀錄 -->
<div class="card">
    <h3 style="font-size:15px;font-weight:700;color:#1a3a6b;margin-bottom:16px;">
        <i class="fas fa-history" style="margin-right:8px;"></i>最近操作紀錄
    </h3>
    <asp:Repeater ID="rpt最近紀錄" runat="server">
    <ItemTemplate>
        <div style="display:flex;align-items:center;gap:10px;padding:9px 0;border-bottom:1px solid #f0f4f8;">
            <div style="width:8px;height:8px;border-radius:50%;background:<%# 取得操作顏色(Convert.ToString(Eval("操作類型"))) %>;flex-shrink:0;"></div>
            <div style="flex:1;min-width:0;">
                <div style="font-size:13px;">
                    <b><%# Eval("操作類型") %></b>
                    <%# Eval("檔案名稱") != DBNull.Value ? " - " + Eval("檔案名稱") : "" %>
                </div>
                <div style="font-size:11px;color:#6b7280;">
                    <%# Eval("操作者IP") %> &bull; <%# 民國日期.轉換(Convert.ToDateTime(Eval("操作時間"))) %>
                </div>
            </div>
        </div>
    </ItemTemplate>
    </asp:Repeater>
    <div style="text-align:right;margin-top:12px;">
        <a href="稽核查詢.aspx" class="btn btn-outline btn-sm">查看全部</a>
    </div>
</div>
</div>

<!-- 即將到期警示 -->
<div class="card" style="margin-top:4px;">
    <h3 style="font-size:15px;font-weight:700;color:#c0392b;margin-bottom:16px;">
        <i class="fas fa-exclamation-triangle" style="margin-right:8px;"></i>即將到期檔案 (7天內)
    </h3>
    <asp:GridView ID="gv即將到期" runat="server" CssClass="data-table" AutoGenerateColumns="false"
                  EmptyDataText="目前無即將到期的檔案" GridLines="None">
        <EmptyDataRowStyle CssClass="alert alert-info" />
        <Columns>
            <asp:BoundField DataField="原始檔名" HeaderText="檔案名稱" />
            <asp:BoundField DataField="組別名稱" HeaderText="組別" />
            <asp:TemplateField HeaderText="到期時間">
                <ItemTemplate><%# 民國日期.轉換(Convert.ToDateTime(Eval("到期時間"))) %></ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="剩餘天數" HeaderText="剩餘天數" />
            <asp:TemplateField HeaderText="操作">
                <ItemTemplate>
                    <a href='檔案瀏覽.aspx?id=<%# Eval("檔案編號") %>' class="btn btn-outline btn-sm">查看</a>
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</div>

</asp:Content>
