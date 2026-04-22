<%@ Page Language="C#" AutoEventWireup="true" CodeFile="登入.aspx.cs" Inherits="登入" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>登入 - 文件管理系統</title>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+TC:wght@300;400;500;700&display=swap" rel="stylesheet">
<link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" rel="stylesheet">
<style>
*{box-sizing:border-box;margin:0;padding:0;}
body{font-family:'Noto Sans TC',sans-serif;background:linear-gradient(135deg,#0f2347,#1a3a6b,#2756a8);min-height:100vh;display:flex;align-items:center;justify-content:center;}
.card{background:white;border-radius:16px;padding:44px;width:420px;box-shadow:0 24px 64px rgba(0,0,0,.4);}
.card::before{content:'';display:block;height:5px;background:linear-gradient(90deg,#1a3a6b,#e8a020);border-radius:3px 3px 0 0;margin:-44px -44px 32px;}
.logo{width:64px;height:64px;background:linear-gradient(135deg,#1a3a6b,#2756a8);border-radius:16px;display:flex;align-items:center;justify-content:center;font-size:28px;color:white;margin:0 auto 18px;box-shadow:0 6px 18px rgba(26,58,107,.3);}
h1{text-align:center;font-size:20px;color:#1a2332;margin-bottom:6px;}
.sub{text-align:center;font-size:13px;color:#6b7280;margin-bottom:24px;}
.fl{margin-bottom:16px;}
.fl label{display:block;font-size:13px;font-weight:600;color:#374151;margin-bottom:5px;}
.inp-wrap{position:relative;}
.inp-wrap i{position:absolute;left:12px;top:50%;transform:translateY(-50%);color:#9ca3af;font-size:14px;}
input{width:100%;padding:10px 12px 10px 36px;border:1.5px solid #d1d5db;border-radius:8px;font-size:14px;font-family:inherit;color:#1a2332;transition:border-color .2s;}
input:focus{outline:none;border-color:#1a3a6b;box-shadow:0 0 0 3px rgba(26,58,107,.1);}
.btn{width:100%;padding:12px;background:linear-gradient(135deg,#1a3a6b,#2756a8);color:white;border:none;border-radius:8px;font-size:15px;font-weight:600;font-family:inherit;cursor:pointer;margin-top:6px;transition:all .2s;}
.btn:hover{transform:translateY(-1px);box-shadow:0 6px 18px rgba(26,58,107,.35);}
.err{background:#fef2f2;border:1px solid #fecaca;color:#dc2626;border-radius:8px;padding:10px 13px;font-size:13px;display:flex;gap:8px;align-items:center;margin-bottom:14px;}
.links{display:flex;justify-content:space-between;margin-top:18px;}
.links a{font-size:12px;color:#1a3a6b;text-decoration:none;}
.links a:hover{text-decoration:underline;}
.time-box{text-align:center;font-size:12px;color:#6b7280;margin:14px 0;padding:8px;background:#f8faff;border-radius:7px;border:1px solid #e0e8f5;}
</style>
</head>
<body>
<form id="form1" runat="server">
<div class="card">
    <div class="logo"><i class="fas fa-folder-open"></i></div>
    <h1>文件管理系統</h1>
    <p class="sub">Document Management System</p>
    <div class="time-box" id="tBox"></div>

    <asp:Panel ID="pnlErr" runat="server" Visible="false">
        <div class="err"><i class="fas fa-exclamation-circle"></i><asp:Label ID="lblErr" runat="server" /></div>
    </asp:Panel>

    <div class="fl">
        <label>姓名代號（登入帳號）</label>
        <div class="inp-wrap">
            <i class="fas fa-id-card"></i>
            <asp:TextBox ID="txtAcc" runat="server" placeholder="請輸入6位數姓名代號" MaxLength="20" />
        </div>
    </div>
    <div class="fl">
        <label>密碼</label>
        <div class="inp-wrap">
            <i class="fas fa-lock"></i>
            <asp:TextBox ID="txtPwd" runat="server" TextMode="Password" placeholder="至少12碼" />
        </div>
    </div>
    <asp:Button ID="btnLogin" runat="server" Text="登入系統" CssClass="btn" OnClick="btnLogin_Click" />

    <div class="links">
        <a href="申請帳號.aspx">申請新帳號</a>
        <a href="忘記密碼.aspx">忘記密碼？</a>
    </div>
</div>
</form>
<script>
function tick(){
    var d=new Date(),y=d.getFullYear()-1911;
    var pad=function(n){return String(n).padStart(2,'0');};
    document.getElementById('tBox').textContent='民國'+y+'年'+pad(d.getMonth()+1)+'月'+pad(d.getDate())+'日 '+pad(d.getHours())+':'+pad(d.getMinutes())+':'+pad(d.getSeconds());
}
tick();setInterval(tick,1000);
</script>
</body>
</html>
