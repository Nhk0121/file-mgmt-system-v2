using System;

public partial class 登入 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!IsPostBack && Session["已登入"] != null)
            Response.Redirect("~/首頁.aspx", false);

        // 第一次執行時初始化超管密碼
        帳號輔助.初始化超管();
    }

    protected void btnLogin_Click(object sender, EventArgs e)
    {
        string 帳號 = txtAcc.Text.Trim();
        string 密碼 = txtPwd.Text;
        string IP  = IP輔助.取得用戶端IP();

        if (string.IsNullOrEmpty(帳號) || string.IsNullOrEmpty(密碼))
        { 顯示錯誤("請輸入帳號和密碼"); return; }

        string 鎖定訊息;
        if (登入安全輔助.已被暫時鎖定(帳號, IP, out 鎖定訊息))
        {
            顯示錯誤(鎖定訊息);
            操作紀錄輔助.記錄登入(帳號, IP, "拒絕", "登入節流鎖定", 鎖定訊息);
            操作紀錄輔助.資安警示("登入鎖定", "中", IP, "登入頁面",
                string.Format("帳號 {0} 因連續失敗已被暫時鎖定", 帳號));
            return;
        }

        var user = 帳號輔助.驗證登入(帳號, 密碼);

        if (user != null)
        {
            帳號輔助.寫入Session(user);
            帳號輔助.更新登入紀錄(Convert.ToInt32(user["帳號編號"]), IP);
            操作紀錄輔助.記錄(null, "登入", IP, "成功", null, null,
                string.Format("帳號 {0} ({1}) 登入", 帳號, user["姓名"]));
            Response.Redirect("~/首頁.aspx", false);
        }
        else
        {
            顯示錯誤("帳號或密碼錯誤，或帳號尚未審核通過");
            操作紀錄輔助.記錄登入(帳號, IP, "失敗",
                string.Format("帳號 {0} 登入失敗", 帳號),
                "帳號或密碼錯誤，或帳號尚未審核通過");
            操作紀錄輔助.資安警示("登入失敗", "中", IP, "登入頁面",
                string.Format("帳號 {0} 嘗試登入失敗", 帳號));
        }
    }

    private void 顯示錯誤(string msg) { pnlErr.Visible = true; lblErr.Text = msg; }
}
