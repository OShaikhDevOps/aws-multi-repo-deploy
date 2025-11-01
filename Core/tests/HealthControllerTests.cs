using Xunit;
using Core.Controllers;
using Microsoft.AspNetCore.Mvc;

namespace Core.Tests;

public class HealthControllerTests
{
    [Fact]
    public void Get_ReturnsOk()
    {
        var controller = new HealthController();
        var result = controller.Get();
        Assert.IsType<OkObjectResult>(result);
    }
}
