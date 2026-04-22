<%@ Page Language="C#" MasterPageFile="~/主版面.master" AutoEventWireup="true" CodeFile="資源回收桶.aspx.cs" Inherits="資源回收桶" Title="資源回收桶" %>
<asp:Content ID="Content1" ContentPlaceHolderID="主內容" runat="server">

<div class="page-header">
    <div>
        <div class="page-title"><i class="fas fa-trash-alt" style="color:#dc2626;margin-right:10px;"></i>資源回收桶</div>
        <div class="page-breadcrumb">文件管理系統 / 資源回收桶 (僅管理員可見)</div>
    </div>
    <asp:Button ID="btn清空回收桶" runat="server" Text="🗑️ 清空全部 (不可復原)" CssClass="btn btn-danger"
                OnClick="btn清空_Click"
                OnClientClick="return confirm('確定清空所有回收桶檔案？此操作不可復原！');" />
</div>

<div class="alert alert-warning">
    <i class="fas fa-exclamation-triangle"></i>
    <div>回收桶內的檔案超過 <b>60天</b> 後系統將自動永久刪除。您也可以手動還原或永久刪除個別檔案。</div>
</div>

<!-- 篩選 -->
<div class="card" style="padding:12px 16px;margin-bottom:16px;">
    <div style="display:flex;gap:10px;align-items:center;">
        <asp:DropDownList ID="dd篩選組別" runat="server" CssClass="form-control" Style="width:140px;" AutoPostBack="true" OnSelectedIndexChanged="重新查詢" />
        <asp:TextBox ID="txt搜尋" runat="server" CssClass="form-control" Style="width:200px;" placeholder="搜尋檔名..." />
        <asp:Button ID="btn搜尋" runat="server" Text="🔍 搜尋" CssClass="btn btn-primary" OnClick="重新查詢" />
        <span style="margin-left:auto;font-size:13px;color:#6b7280;">
            共 <asp:Label ID="lbl筆數" runat="server" Text="0" /> 個檔案
        </span>
    </div>
</div>

<div class="card" style="padding:0;">
    <asp:GridView ID="gv回收桶" runat="server" CssClass="data-table" AutoGenerateColumns="false"
                  GridLines="None" OnRowCommand="gv_RowCommand"
                  EmptyDataText="回收桶是空的 ✓">
        <Columns>
            <asp:TemplateField HeaderText="檔案名稱">
                <ItemTemplate>
                    <div style="font-weight:500;"><%# Eval("原始檔名") %></div>
                    <div style="font-size:11px;color:#9ca3af;"><%# Eval("資料夾路徑") %></div>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="組別名稱" HeaderText="組別" />
            <asp:TemplateField HeaderText="大小">
                <ItemTemplate><%# 格式化大小(Eval("檔案大小")) %></ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="刪除時間">
                <ItemTemplate><%# Eval("刪除時間") == DBNull.Value ? "-" : 民國日期.轉換(Convert.ToDateTime(Eval("刪除時間"))) %></ItemTemplate>
            </asp:TemplateField>
            <asp:BoundField DataField="刪除者IP" HeaderText="刪除者IP" />
            <asp:TemplateField HeaderText="到期刪除">
                <ItemTemplate>
<%# 取得到期顯示(Eval("刪除時間"), Eval("剩餘天數")) %>
                </ItemTemplate>
            </asp:TemplateField>
            <asp:TemplateField HeaderText="操作" ItemStyle-Width="180px">
                <ItemTemplate>
                    <asp:LinkButton runat="server" CssClass="btn btn-success btn-sm" CommandName="還原"
                                    CommandArgument='<%# Eval("檔案編號") %>'
                                    OnClientClick="return confirm('確定還原此檔案至時效區？');">
                        <i class="fas fa-undo"></i> 還原
                    </asp:LinkButton>
                    <a href='Handlers/下載.ashx?id=<%# Eval("檔案編號") %>' class="btn btn-outline btn-sm">
                        <i class="fas fa-download"></i>
                    </a>
                    <asp:LinkButton runat="server" CssClass="btn btn-danger btn-sm" CommandName="永久刪除"
                                    CommandArgument='<%# Eval("檔案編號") %>'
                                    OnClientClick="return confirm('永久刪除此檔案？不可復原！');">
                        <i class="fas fa-times"></i>
                    </asp:LinkButton>
                </ItemTemplate>
            </asp:TemplateField>
        </Columns>
    </asp:GridView>
</div>
</asp:Content>
