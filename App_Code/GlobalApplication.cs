using System;
using System.Web;

public class GlobalApplication : HttpApplication
{
    protected void Application_Error(object sender, EventArgs e)
    {
        Exception ex = Server.GetLastError();
        if (ex == null) return;

        例外處理輔助.記錄例外(ex, "未處理例外", Request != null ? Request.RawUrl : "");

        HttpContext context = HttpContext.Current;
        if (context == null) return;

        bool ajax = (context.Request.Headers["X-Requested-With"] ?? "") == "XMLHttpRequest";
        bool isHandler = (context.Request.CurrentExecutionFilePathExtension ?? "").Equals(".ashx", StringComparison.OrdinalIgnoreCase);

        Server.ClearError();
        context.Response.TrySkipIisCustomErrors = true;

        if (ajax || isHandler)
        {
            context.Response.StatusCode = 500;
            context.Response.ContentType = "application/json";
            context.Response.Write("{\"ok\":false,\"msg\":\"系統發生例外，請稍後再試或通知管理員\"}");
            return;
        }

        context.Response.Redirect("~/錯誤.aspx", false);
    }
}
