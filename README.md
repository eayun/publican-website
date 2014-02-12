publican-website
================

the documents site based publican.

================

step: 
publican create_site --site_config=eayun_docs.cfg --db_file=eayun_docs.db --lang=zh-CN --toc_path=eayun_docs/

cd brandsrc_dir
publican build --formats=xml --langs=all --publish
publican install_brand --web --path=../publican-website/eayun_docs/
