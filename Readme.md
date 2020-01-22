
# OrgTraverse

A small script for extracting the organization data from Active Directory.
And a simple web site to present an organizational chart 

Example organization json;

```javascript
{
  "name": "Mana Ger",
  "title": "CEO",
  "mobile": "123",
  "mail": "manager@example.com",
  "image": "images/manager.bmp",
  "children": [
    {
      "name": "emp1",
      "title": "Employer",
      "mobile": "123",
      "mail": "emp1@example.com",
      "image": "images/emp1.bmp",
      "children": [
        {
          "name": "emp2",
          "title": "Employer",
          "mobile": "123",
          "mail": "emp2@example.com",
          "image": "images/emp2.bmp",
          "children": []
        }
      ]
    },
    {
      "name": "emp1",
      "title": "Employer",
      "mobile": "123",
      "mail": "emp1@example.com",
      "image": "images/emp1.bmp",
      "children": [
        {
          "name": "emp2",
          "title": "Employer",
          "mobile": "123",
          "mail": "emp2@example.com",
          "image": "images/emp2.bmp",
          "children": []
        }
      ]
    }
  ]
}
´´´

## FAQ

- Which chart tool is used?
    - Dabeng's. https://dabeng.github.io/OrgChart/


## Donations (Optional)

- Just give a star to the repo.
