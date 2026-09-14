import com.github.catvod.crawler.Spider;
import com.github.catvod.crawler.SpiderFactory;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStreamWriter;
import java.net.ServerSocket;
import java.net.Socket;
import java.nio.charset.StandardCharsets;

public class CatVodSocketServer {
    private static final int PORT = 18088;
    private static final Gson gson = new Gson();
    private static Spider spider = null;

    public static void main(String[] args) {
        try (ServerSocket serverSocket = new ServerSocket(PORT)) {
            System.out.println("✅ CatVod Socket服务启动成功，端口:" + PORT);
            System.out.println("等待Flutter客户端连接...");

            while (!serverSocket.isClosed()) {
                Socket clientSocket = serverSocket.accept();
                new Thread(() -> handleClient(clientSocket)).start();
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    private static void handleClient(Socket socket) {
        try (BufferedReader in = new BufferedReader(new InputStreamReader(socket.getInputStream(), StandardCharsets.UTF_8));
             OutputStreamWriter out = new OutputStreamWriter(socket.getOutputStream(), StandardCharsets.UTF_8)) {

            String line;
            while ((line = in.readLine()) != null) {
                if (line.isBlank()) continue;
                JsonObject req = JsonParser.parseString(line).getAsJsonObject();
                String action = req.get("action").getAsString();
                JsonObject resp = new JsonObject();

                try {
                    switch (action) {
                        case "loadConfig":
                            String jsonConfig = req.get("config").getAsString();
                            SpiderFactory factory = new SpiderFactory();
                            factory.load(jsonConfig);
                            spider = factory.getSpider();
                            resp.addProperty("code", 200);
                            resp.addProperty("msg", "配置加载成功");
                            break;
                        case "home":
                            if (spider == null) {
                                resp.addProperty("code", 400);
                                resp.addProperty("msg", "请先加载站点配置");
                                break;
                            }
                            String homeData = spider.homeContent();
                            resp = JsonParser.parseString(homeData).getAsJsonObject();
                            break;
                        case "category":
                            String cateId = req.get("cateId").getAsString();
                            String page = req.get("page").getAsString();
                            String cateResult = spider.category(cateId, page);
                            resp = JsonParser.parseString(cateResult).getAsJsonObject();
                            break;
                        case "search":
                            String keyword = req.get("keyword").getAsString();
                            String searchPage = req.get("page").getAsString();
                            String searchResult = spider.searchContent(keyword, searchPage);
                            resp = JsonParser.parseString(searchResult).getAsJsonObject();
                            break;
                        case "detail":
                            String vid = req.get("vid").getAsString();
                            String detailResult = spider.detailContent(vid);
                            resp = JsonParser.parseString(detailResult).getAsJsonObject();
                            break;
                        case "play":
                            String playVid = req.get("vid").getAsString();
                            String flag = req.get("flag").getAsString();
                            var playInfo = spider.playContent(playVid, flag);
                            resp = gson.toJsonTree(playInfo).getAsJsonObject();
                            resp.addProperty("code", 200);
                            break;
                        default:
                            resp.addProperty("code", 404);
                            resp.addProperty("msg", "未知action");
                    }
                } catch (Exception e) {
                    resp.addProperty("code", 500);
                    resp.addProperty("msg", e.getMessage());
                    e.printStackTrace();
                }
                out.write(gson.toJson(resp) + "\n");
                out.flush();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}
