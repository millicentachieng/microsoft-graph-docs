
```Cs

GraphServiceClient graphClient = new GraphServiceClient( authProvider );

var contactFolder = new ContactFolder
{
	DisplayName = "displayName-value",
};

await graphClient.Me.ContactFolders["{id}"].ChildFolders
	.Request()
	.AddAsync(contactFolder);

```