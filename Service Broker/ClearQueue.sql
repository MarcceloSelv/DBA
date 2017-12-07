
declare @conversation_group uniqueidentifier

while(1=1)
begin
    waitfor (
        receive top(1)
        @conversation_group = conversation_group_id
        from dbo.sysEventQueue

    ), timeout 1000;

	
        if (@@rowcount = 0)
        begin
            break
        end
end
