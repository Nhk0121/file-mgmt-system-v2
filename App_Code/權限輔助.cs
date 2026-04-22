using System;
using System.Data;
using System.Web;

/// <summary>
/// 檔案與資料夾存取權限輔助
/// </summary>
public static class 權限輔助
{
    public static bool 已登入()
    {
        var session = HttpContext.Current != null ? HttpContext.Current.Session : null;
        return session != null && session["已登入"] != null;
    }

    public static bool 要求登入(HttpContext context)
    {
        if (已登入()) return true;
        回應錯誤(context, 401, "尚未登入");
        return false;
    }

    public static void 回應錯誤(HttpContext context, int statusCode, string message)
    {
        context.Response.StatusCode = statusCode;
        context.Response.ContentType = "application/json";
        context.Response.ContentEncoding = System.Text.Encoding.UTF8;
        context.Response.Write("{\"ok\":false,\"msg\":\"" + HttpUtility.JavaScriptStringEncode(message ?? "存取失敗") + "\"}");
    }

    public static bool 可存取資料夾(DataRow 資料夾資訊, bool 寫入 = false)
    {
        if (!已登入() || 資料夾資訊 == null) return false;

        string 儲存區 = 資料夾資訊["儲存區類型"].ToString();
        int 組別編號 = Convert.ToInt32(資料夾資訊["組別編號"]);
        int? 我的組別 = 帳號輔助.取得組別編號();

        if (角色輔助.是管理員()) return true;
        if (儲存區 == "資源回收桶") return false;

        if (儲存區 == "永久區")
        {
            if (寫入) return 角色輔助.可操作永久區(組別編號);
            return 角色輔助.可下載永久區();
        }

        if (我的組別 == null || 我的組別.Value != 組別編號) return false;

        return true;
    }

    public static bool 可存取檔案(DataRow 檔案資訊, bool 寫入 = false)
    {
        if (!已登入() || 檔案資訊 == null) return false;

        string 儲存區 = 檔案資訊["儲存區類型"].ToString();
        int 組別編號 = Convert.ToInt32(檔案資訊["組別編號"]);
        string 審核狀態 = 檔案資訊.Table.Columns.Contains("審核狀態")
            ? 檔案資訊["審核狀態"].ToString()
            : "";
        int? 我的組別 = 帳號輔助.取得組別編號();

        if (角色輔助.是管理員()) return true;
        if (儲存區 == "資源回收桶") return false;

        if (儲存區 == "永久區")
        {
            if (寫入) return 角色輔助.可操作永久區(組別編號);
            if (!角色輔助.可下載永久區()) return false;
            if (!string.IsNullOrEmpty(審核狀態) && 審核狀態 != "已通過")
                return 角色輔助.是本組負責人(組別編號);
            return true;
        }

        if (我的組別 == null || 我的組別.Value != 組別編號) return false;

        return true;
    }

    public static bool 可查看儲存區(string 儲存區)
    {
        if (!已登入()) return false;
        if (角色輔助.是管理員()) return true;
        if (儲存區 == "資源回收桶") return false;
        if (儲存區 == "永久區" && !角色輔助.可下載永久區()) return false;
        return 帳號輔助.取得組別編號().HasValue;
    }
}
