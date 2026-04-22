<%@ Page Language="C#" AutoEventWireup="true" CodeFile="忘記密碼.aspx.cs" Inherits="忘記密碼" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<title>忘記密碼 - 文件管理系統</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+TC:wght@400;600;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'Noto Sans TC',sans-serif;background:linear-gradient(135deg,#0f2347,#1a3a6b,#2756a8);min-height:100vh;display:flex;align-items:center;justify-content:center;}
.card{background:white;border-radius:16px;padding:40px;width:420px;box-shadow:0 24px 64px rgba(0,0,0,.4);}
.card::before{content:'';display:block;height:5px;background:linear-gradient(90deg,#1a3a6b,#e8a020);border-radius:3px 3px 0 0;margin:-40px -40px 28px;}
h1{font-size:18px;color:#1a2332;margin-bottom:6px;}
.sub{font-size:13px;color:#6b7280;margin-bottom:22px;}
.fl{margin-bottom:15px;}
.fl label{display:block;font-size:13px;font-weight:600;color:#374151;margin-bottom:5px;}
input{width:100%;padding:9px 12px;border:1.5px solid #d1d5db;border-radius:8px;font-size:13px;font-family:inherit;}
input:focus{outline:none;border-color:#1a3a6b;}
.btn{width:100%;padding:11px;background:#1a3a6b;color:white;border:none;border-radius:8px;font-size:14px;font-weight:600;font-family:inherit;cursor:pointer;margin-top:4px;}
.msg{padding:12px;border-radius:8px;font-size:13px;margin-bottom:14px;}
.ok{background:#f0fdf4;border:1px solid #bbf7d0;color:#166534;}
.err{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;}
.info{background:#eff6ff;border:1px solid #bfdbfe;color:#1e40af;margin-bottom:18px;}
a{display:block;text-align:center;margin-top:14px;color:#1a3a6b;font-size:13px;}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="card">
    <h1><i class="fas fa-key" style="color:#e8a020;margin-right:8px;"></i>忘記密碼</h1>
    <p class="sub">請聯絡管理員協助重設密碼</p>

    <div class="info">
        <i class="fas fa-info-circle"></i>
        本系統密碼採用安全雜湊儲存，管理員無法查看原始密碼。<br>
        請向系統管理員提供您的 <b>姓名</b> 及 <b>姓名代號</b>，由管理員協助重設。
    </div>

    <asp:Panel ID="pnlMsg" runat="server" Visible="false">
        <div class="msg ok"><i class="fas fa-check-circle"></i> <asp:Label ID="lblMsg" runat="server" /></div>
    </asp:Panel>

    <div style="background:#f8faff;border-radius:10px;padding:16px;font-size:13px;color:#374151;line-height:2;">
        <p><b>管理員聯絡方式：</b></p>
        <p><i class="fas fa-phone" style="color:#1a3a6b;margin-right:6px;"></i>分機：<asp:Label ID="lbl管理員分機" runat="server" Text="請洽系統管理員" /></p>
        <p><i class="fas fa-user" style="color:#1a3a6b;margin-right:6px;"></i>管理員：<asp:Label ID="lbl管理員姓名" runat="server" Text="系統管理員" /></p>
    </div>

    <a href="登入.aspx">← 返回登入</a>
</div>
</form>
</body>
</html>