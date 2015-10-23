configuration NewTestConfig
{
    node WSVM1Classic
    {

        windowsFeature IIS
        {
            Ensure = "Absent"
            Name = "web-server"
        }
	
    }

}
