<%@ Page Language="C#" MasterPageFile="~/主版面.master" AutoEventWireup="true" CodeFile="審核管理.aspx.cs" Inherits="審核管理" Title="永久區審核" %>
<asp:Content ID="Content1" ContentPlaceHolderID="主內容" runat="server">

<div class="page-header">
    <div>
        <div class="page-title"><i class="fas fa-clipboard-check" style="color:#1a3a6b;margin-right:10px;"></i>永久區審核管理</div>
        <div class="page-breadcrumb">文件管理系統 / 永久區審核</div>
    </div>
</div>

<asp:Panel ID="pnl非負責人" runat="server" Visible="false">
    <div class="alert alert-warning">
        <i class="fas fa-exclamation-triangle"></i>
        <div>您的IP (<asp:Label ID="lbl您IP" runat="server" />) 目前未設定為任何組別的審核負責人。請聯絡系統管理員設定審核權限。</div>
    </div>
</asp:Panel>

<asp:Panel ID="pnl審核區" runat="server">
    <div class="alert alert-info">
        <i class="fas fa-info-circle"></i>
        <div>您可以審核的組別: <b><asp:Label ID="lbl可審核組別" runat="server" /></b></div>
    </div>

    <div class="card">
        <h3 style="font-size:15px;font-weight:700;color:#1a3a6b;margin-bottom:16px;">待審核檔案清單</h3>
        
        <asp:GridView ID="gv待審核" runat="server" CssClass="data-table" AutoGenerateColumns="false"
                      GridLines="None" OnRowCommand="gv待審核_RowCommand"
                      EmptyDataText="目前無待審核的檔案">
            <Columns>
                <asp:TemplateField HeaderText="檔案名稱">
                    <ItemTemplate>
                        <div style="font-weight:500;"><%# Eval("原始檔名") %></div>
                        <div style="font-size:11px;color:#9ca3af;"><%# Eval("描述") %></div>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="組別名稱" HeaderText="組別" />
                <asp:BoundField DataField="副檔名" HeaderText="類型" />
                <asp:TemplateField HeaderText="上傳時間">
                    <ItemTemplate><%# 民國日期.轉換(Convert.ToDateTime(Eval("上傳時間"))) %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="上傳者IP" HeaderText="上傳者IP" />
                <asp:TemplateField HeaderText="檔案大小">
                    <ItemTemplate>
                        <%# Eval("檔案大小") == DBNull.Value ? "-" : (Convert.ToInt64(Eval("檔案大小"))/1024.0/1024).ToString("F1") + " MB" %>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:TemplateField HeaderText="審核操作" ItemStyle-Width="280px">
                    <ItemTemplate>
                        <div style="display:flex;gap:8px;align-items:center;">
                            <asp:LinkButton runat="server" CssClass="btn btn-success btn-sm" CommandName="通過"
                                            CommandArgument='<%# Eval("檔案編號") %>'
                                            OnClientClick="return confirm('確定通過此檔案審核？')">
                                <i class="fas fa-check"></i> 通過
                            </asp:LinkButton>
                            <asp:LinkButton runat="server" CssClass="btn btn-danger btn-sm" CommandName="未通過"
                                            CommandArgument='<%# Eval("檔案編號") %>'
                                            OnClientClick="return confirm('確定退回此檔案？退回後將移入時效區。')">
                                <i class="fas fa-times"></i> 退回
                            </asp:LinkButton>
                            <a href='Handlers/下載.ashx?id=<%# Eval("檔案編號") %>' class="btn btn-outline btn-sm">
                                <i class="fas fa-download"></i> 下載查看
                            </a>
                        </div>
                    </ItemTemplate>
                </asp:TemplateField>
            </Columns>
        </asp:GridView>
    </div>

    <!-- 已審核紀錄 -->
    <div class="card">
        <h3 style="font-size:15px;font-weight:700;color:#1a3a6b;margin-bottom:16px;">近期審核紀錄</h3>
        <asp:GridView ID="gv審核紀錄" runat="server" CssClass="data-table" AutoGenerateColumns="false"
                      GridLines="None" EmptyDataText="尚無審核紀錄">
            <Columns>
                <asp:BoundField DataField="原始檔名" HeaderText="檔案名稱" />
                <asp:BoundField DataField="組別名稱" HeaderText="組別" />
                <asp:TemplateField HeaderText="審核狀態">
                    <ItemTemplate>
                        <span class="tag tag-<%# Eval("審核狀態") %>"><%# Eval("審核狀態") %></span>
                    </ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="審核者IP" HeaderText="審核者IP" />
                <asp:TemplateField HeaderText="審核時間">
                    <ItemTemplate><%# Eval("審核時間") == DBNull.Value ? "-" : 民國日期.轉換(Convert.ToDateTime(Eval("審核時間"))) %></ItemTemplate>
                </asp:TemplateField>
                <asp:BoundField DataField="審核備註" HeaderText="備註" />
            </Columns>
        </asp:GridView>
    </div>
</asp:Panel>

</asp:Content>
