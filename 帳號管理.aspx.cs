using System;
using System.Web.UI.WebControls;

public partial class 帳號管理 : System.Web.UI.Page
{
    private string 目前Tab { get { return ViewState["tab"] != null ? ViewState["tab"].ToString() : "待審核"; } set { ViewState["tab"] = value; } }

    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["已登入"] == null) Response.Redirect("~/登入.aspx");
        if (!角色輔助.可管理帳號()) Response.Redirect("~/首頁.aspx");
        if (!IsPostBack) { 載入組別(); 查詢(); }
    }

    private void 載入組別()
    {
        var dt = 資料庫輔助.查詢("SELECT 組別編號, 組別名稱 FROM 組別設定 WHERE 是否啟用=1 ORDER BY 組別編號");
        ddNew組別.DataSource = dt;
        ddNew組別.DataTextField = "組別名稱";
        ddNew組別.DataValueField = "組別編號";
        ddNew組別.DataBind();
        ddNew組別.Items.Insert(0, new ListItem("-- 不指定 --", ""));
    }

    private void 查詢()
    {
        // 待審核數量
        var 數 = 資料庫輔助.查詢單值("SELECT COUNT(*) FROM 使用者帳號 WHERE 帳號狀態='待審核'");
        int 待審 = Convert.ToInt32(數);
        lbl待審核數.Text = 待審 > 0 ? 待審.ToString() : "";
        lbl待審核數.Visible = 待審 > 0;

        string where = "WHERE 1=1";
        var 參數 = new System.Collections.Generic.List<System.Data.SqlClient.SqlParameter>();

        if (目前Tab != "全部")
        {
            where += " AND u.帳號狀態=@狀態";
            參數.Add(資料庫輔助.P("@狀態", 目前Tab));
        }
        if (!string.IsNullOrEmpty(txt搜尋.Text.Trim()))
        {
            where += " AND (u.姓名 LIKE @kw OR u.登入帳號 LIKE @kw OR u.姓名代號 LIKE @kw)";
            參數.Add(資料庫輔助.P("@kw", "%" + txt搜尋.Text.Trim() + "%"));
        }

        // 超管只能被超管看到
        if (!角色輔助.是超管()) where += " AND u.角色 != '超管'";

        var dt = 資料庫輔助.查詢(string.Format(@"
            SELECT u.帳號編號, u.登入帳號, u.姓名, u.姓名代號, u.角色, u.員工類型,
                   u.課別, u.分機, u.帳號狀態, u.申請時間, u.最後登入, u.最後登入IP,
                   ISNULL(g.組別名稱,'(無)') AS 組別名稱
            FROM 使用者帳號 u
            LEFT JOIN 組別設定 g ON u.組別編號=g.組別編號
            {0} ORDER BY u.申請時間 DESC", where), 參數.ToArray());

        gvAccounts.DataSource = dt;
        gvAccounts.DataBind();

        // 標籤樣式
        tab待審核.CssClass = 目前Tab == "待審核" ? "tab-btn on" : "tab-btn";
        tab啟用.CssClass   = 目前Tab == "啟用"   ? "tab-btn on" : "tab-btn";
        tab停用.CssClass   = 目前Tab == "停用"   ? "tab-btn on" : "tab-btn";
        tab全部.CssClass   = 目前Tab == "全部"   ? "tab-btn on" : "tab-btn";
    }

    protected void 切換Tab(object sender, EventArgs e)
    {
        var btn = sender as LinkButton;        目前Tab = btn != null ? btn.CommandArgument : "待審核";
        查詢();
    }

    protected void btn搜尋_Click(object sender, EventArgs e) { 查詢(); }

    protected void gv_RowCommand(object sender, GridViewCommandEventArgs e)
    {
        int id = int.Parse(e.CommandArgument.ToString());
        string 操作者 = 帳號輔助.取得帳號編號().ToString();

        if (e.CommandName == "核准")
        {
            資料庫輔助.執行(@"UPDATE 使用者帳號 SET 帳號狀態='啟用', 核准時間=GETDATE(), 核准者帳號=@者
                              WHERE 帳號編號=@id",
                資料庫輔助.P("@者", 操作者), 資料庫輔助.P("@id", id));
            顯示成功("帳號已核准啟用");
        }
        else if (e.CommandName == "停用")
        {
            資料庫輔助.執行("UPDATE 使用者帳號 SET 帳號狀態='停用' WHERE 帳號編號=@id AND 角色!='超管'",
                資料庫輔助.P("@id", id));
            顯示成功("帳號已停用");
        }
        else if (e.CommandName == "啟用")
        {
            資料庫輔助.執行("UPDATE 使用者帳號 SET 帳號狀態='啟用' WHERE 帳號編號=@id",
                資料庫輔助.P("@id", id));
            顯示成功("帳號已啟用");
        }
        else if (e.CommandName == "重設密碼")
        {
            // 重設為 Admin@123456
            帳號輔助.修改密碼(id, "Admin@123456");
            顯示成功("密碼已重設為 Admin@123456，請通知使用者登入後自行修改");
            操作紀錄輔助.記錄(null, "重設密碼", IP輔助.取得用戶端IP(), "成功", null, null,
                string.Format("管理員重設帳號 {0} 的密碼", id));
        }

        查詢();
    }

    // 角色變更（JS PostBack）
    protected void btnRolePB_Click(object sender, EventArgs e)
    {
        string act  = hfRoleAct.Value;
        string data = hfRoleData.Value;
        if (act == "setRole")
        {
            var p = data.Split('|');
            if (p.Length == 2)
            {
                int id = int.Parse(p[0]);
                string role = p[1];
                // 不允許隨意設置超管（只有現任超管才能設）
                if (role == "超管" && !角色輔助.是超管())
                { 顯示錯誤("只有超管才能設定超管角色"); 查詢(); return; }
                // 不允許修改超管帳號（除非操作者也是超管）
                var chk = 資料庫輔助.查詢("SELECT 角色 FROM 使用者帳號 WHERE 帳號編號=@id",
                    資料庫輔助.P("@id", id));
                if (chk.Rows.Count > 0 && chk.Rows[0]["角色"].ToString() == "超管" && !角色輔助.是超管())
                { 顯示錯誤("無法修改超管帳號角色"); 查詢(); return; }

                資料庫輔助.執行("UPDATE 使用者帳號 SET 角色=@role WHERE 帳號編號=@id",
                    資料庫輔助.P("@role", role), 資料庫輔助.P("@id", id));
                顯示成功(string.Format("帳號角色已更新為「{0}」", role));
            }
        }
        查詢();
    }

    // 新增外包帳號
    protected void btnNew_Click(object sender, EventArgs e)
    {
        string 姓名 = txtNew姓名.Text.Trim();
        string 代號 = txtNew代號.Text.Trim();
        string 課別 = txtNew課別.Text.Trim();
        string 分機 = txtNew分機.Text.Trim();
        string 密碼 = txtNew密碼.Text;
        string 組別Str = ddNew組別.SelectedValue;

        if (string.IsNullOrEmpty(姓名) || 代號.Length != 6)
        { 顯示錯誤("請填入姓名及6位數姓名代號"); return; }
        if (!密碼輔助.密碼強度合格(密碼))
        { 顯示錯誤("密碼至少需要12個字元"); return; }

        int? 組別編號 = string.IsNullOrEmpty(組別Str) ? (int?)null : int.Parse(組別Str);
        string 建立者 = HttpContext.Current.Session["登入帳號"].ToString();
        string 錯誤 = 帳號輔助.新增帳號申請(姓名, 代號, 組別編號, 課別, 分機, 密碼, "外包", 建立者);

        if (!string.IsNullOrEmpty(錯誤)) { 顯示錯誤(錯誤); return; }

        txtNew姓名.Text = txtNew代號.Text = txtNew課別.Text = txtNew分機.Text = txtNew密碼.Text = "";
        顯示成功(string.Format("外包帳號「{0}」({1})已建立並啟用", 姓名, 代號));
        查詢();
    }

    private void 顯示成功(string msg) { pnlMsg.Visible = true; pnlErr.Visible = false; lblMsg.Text = msg; }
    private void 顯示錯誤(string msg) { pnlErr.Visible = true; pnlMsg.Visible = false; lblErr.Text = msg; }
}
