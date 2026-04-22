using System;
public partial class 忘記密碼 : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        // 顯示超管資訊
        var dt = 資料庫輔助.查詢(
            "SELECT 姓名, 分機 FROM 使用者帳號 WHERE 角色='超管' AND 帳號狀態='啟用'");
        if (dt.Rows.Count > 0)
        {
            lbl管理員姓名.Text = dt.Rows[0]["姓名"].ToString();
            string 分機 = dt.Rows[0]["分機"].ToString();
            lbl管理員分機.Text = string.IsNullOrEmpty(分機) ? "請洽管理員" : 分機;
        }
    }
}
