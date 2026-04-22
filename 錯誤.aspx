<%@ Page Language="C#" %>
<!DOCTYPE html>
<html lang="zh-TW">
<head runat="server">
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title>系統錯誤</title>
<style>
body{margin:0;font-family:'Noto Sans TC',sans-serif;background:linear-gradient(135deg,#f4f7fb,#e7eef8);min-height:100vh;display:flex;align-items:center;justify-content:center;color:#1f2937}
.card{width:min(560px,92vw);background:#fff;border-radius:18px;padding:36px;box-shadow:0 18px 48px rgba(15,35,71,.15)}
.icon{width:64px;height:64px;border-radius:18px;background:#fee2e2;color:#b91c1c;display:flex;align-items:center;justify-content:center;font-size:30px;margin-bottom:18px}
h1{margin:0 0 8px;font-size:24px}
p{margin:0 0 12px;line-height:1.7;color:#4b5563}
a{display:inline-block;margin-top:10px;color:#1d4ed8;text-decoration:none;font-weight:600}
</style>
</head>
<body>
    <div class="card">
        <div class="icon">!</div>
        <h1>系統暫時無法完成這個操作</h1>
        <p>錯誤已被記錄。請稍後重新嘗試；如果持續發生，請提供操作時間與頁面路徑給管理員協助排查。</p>
        <a href="首頁.aspx">返回首頁</a>
    </div>
</body>
</html>
